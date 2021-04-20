module Hammerstone::Refine
  class Filter
    include ActiveModel::Validations
    include ActiveModel::Callbacks
    include TracksPendingRelationshipSubqueries
    #Revisit this validation structure
    define_model_callbacks :initialize, only: [:after]
    after_initialize :valid?

    attr_reader :blueprint

    def initialize(blueprint)
      run_callbacks :initialize do
        #If using this in test mode, `blueprint` will be an instance of
        #`Blueprint` and the value must be extracted
        if blueprint.is_a? Blueprints::Blueprint
          blueprint = blueprint.to_array
        end
        @blueprint = blueprint
        @relation = initial_query
        @immediately_commit_pending_relationship_subqueries = false
      end
    end

    def initial_query
      raise NotImplementedError
    end

    def table
      @table ||= initial_query.model.arel_table
    end

    def get_query
      if blueprint.present?
        @relation.where(group(make_sub_query(blueprint)))
      else
        @relation
      end
    end

    def add_nodes_to_query(subquery:, nodes:, query_method:)
      # Apply existing nodes to existing subquery
      if subquery.present? && nodes.present?
        if query_method == 'and'
          # Apply the nodes using the AREL AND method
          subquery = subquery.send(query_method, group(nodes))
        else
          # Override the AREL OR method in order to remove the parens
          subquery = Arel::Nodes::Or.new(subquery, group(nodes))
        end
      # No nodes returned, do nothing
      elsif subquery.present? && nodes.blank?
        subquery
      # Subquery has not yet been initialized, initialize with new nodes
      elsif subquery.blank? && nodes.present?
        subquery = group(nodes)
      end
      subquery
    end

    def make_sub_query(modified_blueprint, depth = 0, subquery=nil)
      # Need index control to directly skip indicies in fast forward (recursive call)
      index = 0
      while index < modified_blueprint.length
        criterion = modified_blueprint[index]
        # Decreasing depth, pass control back to caller
        break if criterion[:depth] < depth

        # If it's a conjunction, the next condition will handle it.
        if criterion[:type] == 'conjunction'
          index +=1
          next
        end

        # Check the word on the previous blueprint method. If it is not 'and'....?
        if index == 0
          query_method = 'and'
        else
          query_method = modified_blueprint[index -1][:word] == 'and' ? 'and' : 'or'
        end

        # If the new depth is deeper than our current depth, that means we're
        # starting a new group. We'll recursively call this method again
        # with a subset of the blueprint.
        if criterion[:depth] > depth
          # Modify the array to send in the elements not yet handled (depth>current depth)
          new_depth_array = modified_blueprint[index..-1]

          # Return the nodes in () for elements on the same depth
          recursive_nodes = make_sub_query(new_depth_array, depth + 1)

          # Add the recursive subquery nodes to the existing query and modify the query
          subquery = add_nodes_to_query(subquery: subquery, nodes: recursive_nodes, query_method: query_method)

          for cursor in index..modified_blueprint.length-1 do
            if modified_blueprint[cursor][:depth] <= depth
              break
            end
          end

          # Skip indexes handled by recursive call
          index = cursor + 1
          next
        end
        # If there are any ORs at this depth, commit subqueries
        if modified_blueprint.select{|item| (item[:type] == "conjunction" && item[:word] == "or" && item[:depth] == depth)}.present?
          @immediately_commit_pending_relationship_subqueries = true
        else
          @immediately_commit_pending_relationship_subqueries = false
        end
        # If it is a relationship attribute apply_condition will call apply_relationship_attribute which will set up the pending relationship
        # subquery but will not return a value.
        # apply condition is NOT idempotent, hence the placeholder var
        nodes_to_apply = apply_condition(criterion)
        subquery = add_nodes_to_query(subquery: subquery, nodes: nodes_to_apply, query_method: query_method)

        if @immediately_commit_pending_relationship_subqueries.present?
          committed_nodes_from_pending = commit_pending_relationship_subqueries
          subquery = add_nodes_to_query(subquery: subquery, nodes: committed_nodes_from_pending, query_method: query_method)
        end
        index += 1
      end

      final_depth_nodes = commit_pending_relationship_subqueries
      subquery = add_nodes_to_query(subquery: subquery, nodes: final_depth_nodes, query_method: query_method)
      subquery
    end

    def group(nodes)
      table.grouping(nodes)
    end

    def apply_condition(criterion)
      current_condition = get_condition_for_criterion(criterion)
      if current_condition
        current_condition.apply(criterion[:input], table, initial_query)
      end
    end

    def get_condition_for_criterion(criterion)
      # returns the object that matches the condition. Adds errors if not found.
      # This checks the id on the condition such as text_test
      returned_object = conditions.find { |condition| condition.id == criterion[:condition_id] }

      if returned_object.nil?
        errors.add(:filter, "The condition ID #{criterion[:condition_id]} was not found")
      else
        # Set filter variable on condition
        instantiate_condition(returned_object)
      end
      # Must duplicate the condition so nested attributes don't bleed into one another
      returned_object.dup
    end

    def configuration
      {
        type: 'Hammerstone',
        class_name: self.class.name,
        blueprint: @blueprint,
        conditions: conditions_to_array,
        stable_id: 'dontcare'
      }
    end

    def conditions_to_array
      # Set filter object on condition and return to_array
      conditions.map{|condition| instantiate_condition(condition) }.map(&:to_array)
    end

    def instantiate_condition(condition_class)
      condition_class.set_filter(self)
    end
  end
end

