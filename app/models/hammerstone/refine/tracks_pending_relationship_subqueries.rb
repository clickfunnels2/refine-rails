module Hammerstone::Refine
  module TracksPendingRelationshipSubqueries

    def pending_relationship_subquery_depth
      @pending_relationship_subquery_depth ||= []
    end

    def pending_relationship_subqueries
      @pending_relationship_subqueries ||= {}
    end

    def set_pending_relationship(relation, instance)
      pending_relationship_subquery_depth << relation
      build_keys_for_pending_relationship_subqueries(get_current_relationship)
      pending_relationship_subqueries.dig(*get_current_relationship)[:instance] = instance
    end


    def get_current_relationship
      pending_relationship_subquery_depth.join(".children.").split(".").map(&:to_sym)
    end

    def add_pending_where_in_relationship_subquery(subquery: , primary_key: , secondary_key: )
      add_pending_relationship_subquery(subquery: subquery, primary_key: primary_key, secondary_key: secondary_key)
    end

    def build_keys_for_pending_relationship_subqueries(array_of_keys)
      # Example array of keys [:user, :children, :notes]
      # This will give the values a default value of hash and overwrite existing values if they exist
      array_of_keys.each_with_index do |key, index|
        # If key exists, continue to next level (for nested relationships)
        if pending_relationship_subqueries.dig(key)
          next
        else
          # Handle initial case
          if index == 0
            pending_relationship_subqueries[key] = {}
          else
            # Handle nested keys
            existing_keys = array_of_keys[0..index-1]
            pending_relationship_subqueries.dig(*existing_keys)[key] = {}
          end
        end
      end
    end

    def add_pending_relationship_subquery(subquery:, primary_key: , secondary_key: nil)
      # Add key, query, and secondary keys at the correct depth
      # Key path is built in set pending relationship
      pending_relationship_subqueries.dig(*get_current_relationship)[:key] = primary_key
      pending_relationship_subqueries.dig(*get_current_relationship)[:query] = subquery
      pending_relationship_subqueries.dig(*get_current_relationship)[:secondary] = secondary_key
    end

    def get_pending_relationship_instance
      get_pending_relationship_item("instance")
    end

    def get_pending_relationship_item(key)
      pending_relationship_subqueries.dig(*get_current_relationship, key.to_sym)
    end

    def relationship_supports_collapsing(instance)
      (instance.is_a? ActiveRecord::Reflection::BelongsToReflection) || (instance.is_a? ActiveRecord::Reflection::HasOneReflection)
    end

    def release_pending_relationship
      instance = get_pending_relationship_instance
      subset_hash_values = pending_relationship_subqueries.dig(*get_current_relationship)
      popped = pending_relationship_subquery_depth.pop

      subset_hash = {}
      subset_hash[popped] = subset_hash_values

      return if relationship_supports_collapsing(instance)

      current = get_current_relationship
      if current.blank?
        @immediately_commit_pending_relationship_subqueries = true
        return
      end
      query = pending_relationship_subqueries.dig(*current)[:query]

      pending_relationship_subqueries.dig(*current)[:children].except!(popped.to_sym)
      pending_relationship_subqueries.dig(*current)[:query] = commit_subset(query: query, subset: subset_hash)
    end

    def commit_pending_relationship_subqueries
      applied_query = commit_subset(subset: pending_relationship_subqueries)
      @pending_relationship_subqueries = {}
      applied_query
    end

    def commit_subset(query:nil, subset:)
      # Turn pending subqueries into nodes to apply in the filter

      subset.each do |relation, subquery|
        child_nodes = subquery.dig(:children)
        if child_nodes.present?
          commit_subset(query: subquery[:query], subset: child_nodes)
        end

        parent_table = subquery[:instance].active_record.arel_table
        linking_key = subquery[:key]
        temp_query = subquery[:query]

        if query.present?
          # If query is a Select Manager ("SELECT....") we are deeply nested and need to build the query
          # with a WHERE statement
          if query.is_a? Arel::SelectManager
            query = query.where(parent_table["#{linking_key}"].in(temp_query))
          else
            # Otherwise we are joining nodes, which requires an AND statement (ORs are immediately commited)
            query = query.and(parent_table["#{linking_key}"].in(temp_query))
          end
        else
          query = parent_table["#{linking_key}"].in(temp_query)
        end
      end
      query
    end

    def get_pending_relationship_subquery
      get_pending_relationship_item('query')
    end
  end
end