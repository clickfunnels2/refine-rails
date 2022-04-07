module Hammerstone::Refine
  module TracksPendingRelationshipSubqueries
    def pending_relationship_subquery_depth
      @pending_relationship_subquery_depth ||= []
    end

    def pending_relationship_subqueries
      # The Hash.new block will dynamically created multi-level nested keys
      # Note: Will create a value of {} when accessed with `dig`
      @pending_relationship_subqueries ||= Hash.new { |h, k| h[k] = h.dup.clear }
    end

    # Allow filter refinements to be collapsable in order to slot them in a the appropriate depth
    def allow_pending_relationship_to_collapse
      pending_relationship_subqueries.dig(*get_current_relationship)[:collapsible] = true
    end

    def set_pending_relationship(relation, instance)
      pending_relationship_subquery_depth << relation.to_sym
      # this populates modelA[:children][:modelB]
      pending_relationship_subqueries.dig(*get_current_relationship)[:instance] = instance
    end

    def get_current_relationship
      pending_relationship_subquery_depth.join(".children.").split(".").map(&:to_sym)
    end

    def add_pending_joins_relationship_subquery(subquery:)
      add_pending_relationship_subquery(subquery: subquery, primary_key: JOINS)
    end

    def add_pending_relationship_subquery(subquery:, primary_key:, secondary_key: nil)
      # Add key, query, and secondary keys at the correct depth
      pending_relationship_subqueries.dig(*get_current_relationship)[:key] = primary_key
      pending_relationship_subqueries.dig(*get_current_relationship)[:query] = subquery
      pending_relationship_subqueries.dig(*get_current_relationship)[:secondary] = secondary_key
    end

    def get_pending_relationship_instance
      get_pending_relationship_item("instance")
    end

    def get_pending_relationship_item(key)
      # Digging for a particular key will create a {} value, must check presence
      if pending_relationship_subqueries.dig(*get_current_relationship, key.to_sym).present?
        pending_relationship_subqueries.dig(*get_current_relationship, key.to_sym)
      else
        nil
      end
    end

    def set_pending_relationship_subquery_wrapper(callback)
      pending_relationship_subqueries.dig(*get_current_relationship)[:wrapper] = callback
    end

    def relationship_supports_collapsing(instance)
      if get_current_relationship.present?
        return true if pending_relationship_subqueries.dig(*get_current_relationship)[:collapsible] == true
      end

      (instance.is_a? ActiveRecord::Reflection::BelongsToReflection) || (instance.is_a? ActiveRecord::Reflection::HasOneReflection)
    end

    def release_pending_relationship
      instance = get_pending_relationship_instance
      # Pop off the last key (last relationship)
      popped = pending_relationship_subquery_depth.pop.to_sym
      return if relationship_supports_collapsing(instance)
      current = get_current_relationship
      if current.blank?
        @immediately_commit_pending_relationship_subqueries = true
        return
      end
      # Grab the query one level higher than the current stack (removed during pop)
      query = pending_relationship_subqueries.dig(*current)[:query]
      # Build hash to send to commit_subset with popped -> value at popped
      subset = {}
      subset[popped] = pending_relationship_subqueries.dig(*current)[:children][popped]
      # Remove popped from pending relationships subqueries -> handled in commit_subset
      pending_relationship_subqueries.dig(*current)[:children].except!(popped)
      pending_relationship_subqueries.dig(*current)[:query] = commit_subset(subset: subset, query: query)
    end

    def commit_pending_relationship_subqueries
      applied_query = commit_subset(subset: pending_relationship_subqueries)
      @pending_relationship_subqueries = Hash.new { |h, k| h[k] = h.dup.clear }
      applied_query
    end

    def commit_subset(subset:, query: nil)
      # Turn pending subqueries into nodes to apply in the filter
      # Subquery below is the hash value with has a subquery key.
      subset.each do |relation, subquery|
        if subquery.dig(:children).present?
          # Send in the values at children as the subset hash and remove from existing subquery
          child_nodes = subquery.delete(:children)
          # If there are children, we recursively call this method again
          # to build up the inner (child) queries first. This allows us
          # to intelligently nest multiple levels of relationships.
          commit_subset(query: subquery[:query], subset: child_nodes)
        end
        # If the subquery has a wrapper proc we are dealing with a compare to 0 situation
        if subquery.dig(:wrapper).respond_to? :call
          subquery[:query] = subquery[:wrapper].call(subquery[:query], subquery[:key], subquery[:secondary])
        end
        parent_table = subquery[:instance].active_record.arel_table
        linking_key = subquery[:key]
        temp_query = subquery[:query]
        if query.present?
          # If query is a Select Manager (“SELECT....“) we are deeply nested and need to build the query
          # with a WHERE statement
          if query.is_a? Arel::SelectManager
            if (temp_query.is_a? Arel::SelectManager) && ENV["MULTIPLE_DB_1"]
              # TODO compare query to temp_query and see if they are on different dbs. If they are,
              # execute temp query
              # Switch to correct db to execute
              ActiveRecord::Base.establish_connection :workspace
              array_of_ids = ActiveRecord::Base.connection.exec_query(temp_query.to_sql).rows.flatten
              query.where(parent_table[linking_key.to_s].in(array_of_ids))
            else
              # Same db, don’t decompose temp_query
              # query is AREL select manager
              # Where’s called on AREL select managers modify the object in place
              query.where(parent_table[linking_key.to_s].in(temp_query))
            end
          else
            # Otherwise we are joining nodes, which requires an AND statement (ORs are immediately commited)
            # The group() in front of query is required for nested relationship attributes.
            query = group(query).and(group(parent_table[linking_key.to_s].in(temp_query)))
          end
        else
          if (temp_query.is_a? Arel::SelectManager) && ENV["MULTIPLE_DB_2"]
            # somehow compare query to temp_query and see if they are on different dbs. If they are,
            # execute temp query
            # Returns active record result object, then pluck ids (maybe not necessary)
            # Switch to correct db to execute
            ActiveRecord::Base.establish_connection :workspace
            array_of_ids = ActiveRecord::Base.connection.exec_query(temp_query.to_sql).rows.flatten
            query = parent_table[linking_key.to_s].in(array_of_ids)
          else
            # Don’t decompose temp_query
            # query is AREL select manager
            # Where’s called on AREL select managers modify the object in place
            query = parent_table[linking_key.to_s].in(temp_query)
          end
        end
      end
      query
    end

    def get_pending_relationship_subquery
      get_pending_relationship_item("query")
    end
  end
end
