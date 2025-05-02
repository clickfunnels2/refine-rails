module Refine::Conditions
  module SupportsFlatQueries

    LEFT_JOIN_CLAUSES = [
      Refine::Conditions::Clauses::NOT_IN,
      Refine::Conditions::Clauses::NOT_SET,
      Refine::Conditions::Clauses::DOESNT_EQUAL,
      Refine::Conditions::Clauses::DOESNT_CONTAIN
    ]
    
    # Applies the criterion which can be a relationship condition
    #
    # @param [Hash] input The user's input
    # @param [Arel::Table] table The arel_table the query is built on 
    # @param [ActiveRecord::Relation] initial_query The base query the query is built on 
    # @param [Bool] inverse_clause Whether to invert the clause
    # @param [Bool] apply_condition_on_join Whether to apply the condition on the join instead of the root query
    # @return [Arel::Node] 
    # This is mostly a copy of the `apply` method from the Condition module, but avoids recursion and the pending_subquery system
    def apply_flat(input, table, initial_query, inverse_clause=false, apply_condition_on_join=false)
      table ||= filter.table
      @is_flat_query = true
      # Ensurance validations are checking the developer configured correctly
      run_ensurance_validations
      # Allow developer to modify user input
      # TODO run_before_validate(input) -> what is this for?

      run_before_validate_validations(input)

      # TODO Determine right place to set the clause
      validate_user_input(input)
      if input.dig(:filter_refinement).present?

        filter_condition = call_proc_if_callable(@filter_refinement_proc)
        # Set the filter on the filter_condition to be the current_condition's filter
        filter_condition.set_filter(filter)
        filter_condition.is_refinement = true

        filter_condition.apply(input.dig(:filter_refinement), table, initial_query)
        input.delete(:filter_refinement)
      end

      if is_relationship_attribute?
        return handle_flat_relational_condition(input: input, table: table, query: initial_query, inverse_clause: inverse_clause, apply_condition_on_join: apply_condition_on_join)
      end
      # Not a relationship attribute, apply condition normally
      nodes = apply_condition(input, table, inverse_clause)
      if !is_refinement && has_any_refinements?
        refined_node = apply_refinements(input)
        # Count refinement will return nil because it directly modified pending relationship subquery
        nodes = nodes.and(refined_node) if refined_node
      end
      nodes
    end

    def handle_flat_relational_condition(input:, table:, query:, inverse_clause:, apply_condition_on_join: false)
      model_class = query.model
      condition_joins = []
      condition_nodes = nil
      while @attribute.include?(".")
        puts "Attribute: #{@attribute}"
        forced_id = false
        # Split on first .
        decompose_attribute = @attribute.split(".", 2)
        # Attribute now is the back half of the initial attribute
        @attribute = decompose_attribute[1]
        # Relation to be handled
        relation = decompose_attribute[0]

        puts "RELATION: #{relation}"
        puts "Reflecting #{model_class} on #{relation}"
        instance = model_class.reflect_on_association(relation.to_sym)

        if @attribute == "id"
          # We're referencing a primary key ID, so we dont need the final join table and
          # can just reference the foreign key of the previous step in the relation chain
          through_reflection = get_through_reflection(instance: instance, relation: relation)
          unless condition_uses_different_database?(through_reflection.klass, query.model)
            forced_id = true
            @attribute = get_foreign_key_from_relation(instance: instance, reflection: through_reflection)
            unless condition_uses_different_database?(model_class, query.model)
              condition_joins << through_reflection.name
            end
          end
        else
          # Track the loop iteration of needing joins.
          # The resulting array will be used to construct a nested joins statement
          # IE: [forms_submissions, forms_submissions_answers] will later be converted to forms_submissions: {forms_submissions_answers: {}}
          unless condition_uses_different_database?(model_class, query.model)
            condition_joins << relation
          end
        end
        model_class = instance.class_name.safe_constantize
        puts "MODEL CLASS: #{model_class}"
       
      end # End of while loop


      if condition_joins.any?
        # Copied from apply_flat_relational_condition - need to refactor
        if through_reflection
          # If through reflection is passed in (due to an association only referencing the id)
          # use that to get the table and class
          relation_table_being_queried = through_reflection.klass.arel_table
          relation_class = through_reflection.klass
        else
          # Otherwise, use the instance to get the table and class.
          relation_table_being_queried = instance.class_name.safe_constantize&.arel_table
          relation_class = instance.class_name.safe_constantize
        end
  
        instance = get_reflection_object(query, relation) if forced_id
  
        key_1 = key_1(instance)
        key_2 = key_2(instance) 

        # Ensure we're aliasing the table for the WHERE clause if the condition is used more than once. 
        if apply_condition_on_join 
          pending_join_value = filter.pending_joins[relation_table_being_queried.table_name] || {}
          current_join_count = pending_join_value[:count] || 0
          alias_name = "#{relation_table_being_queried.table_name}_#{current_join_count + 1}"
          relation_table_being_queried = relation_table_being_queried.alias(alias_name)
        end

        if forced_id
          condition_nodes = apply(input, relation_table_being_queried, relation_class, inverse_clause, key_2)
        else
          condition_nodes = apply(input, relation_table_being_queried, relation_class, inverse_clause)
        end
        # end of copied code
        root_level_condition_to_add = add_pending_joins_if_needed(input: input, joins_array: condition_joins, through_reflection: through_reflection, on_condition: condition_nodes)
        # If the condition is used just once, we need to apply the condition normally
        unless apply_condition_on_join
          return apply_flat_relational_condition(instance: instance, relation: relation, through_reflection: through_reflection, input: input, query: query, inverse_clause: inverse_clause, forced_id: forced_id)
        end
        root_level_condition_to_add
      else
        apply_flat_relational_condition(instance: instance, relation: relation, through_reflection: through_reflection, input: input, query: query, inverse_clause: inverse_clause, forced_id: forced_id)
      end
    end

    # apply_flat_relational_condition
    # instance: The reflection object for the relationship
    # relation: The name of the relationship
    # through_reflection: The reflection object for the through relationship if applicable. Might be nil
    # input: The user input for the condition
    # query: The base query the condition is being applied to
    # inverse_clause: Whether to invert the clause
    # forced_id: Whether to force the ID of the instance to be used. This is used when the condition is referencing a primary key
    def apply_flat_relational_condition(instance:, relation:, through_reflection:, input:,  query:, inverse_clause:, forced_id: false)
      unless instance
        raise "Relationship does not exist for #{relation}."
      end

      if through_reflection
        # If through reflection is passed in (due to an association only referencing the id)
        # use that to get the table and class
        relation_table_being_queried = through_reflection.klass.arel_table
        relation_class = through_reflection.klass
      else
        # Otherwise, use the instance to get the table and class.
        relation_table_being_queried = instance.class_name.safe_constantize&.arel_table
        relation_class = instance.class_name.safe_constantize
      end

      instance = get_reflection_object(query, relation) if forced_id

      key_1 = key_1(instance)
      key_2 = key_2(instance)
      if condition_uses_different_database?(relation_class, query.model)
        nodes = handle_flat_cross_database_condition(root_model: query.model, input: input, relation_class: relation_class, relation_table_being_queried: relation_table_being_queried, inverse_clause: inverse_clause, key_1: key_1, key_2: key_2)  
      else
        if forced_id
          nodes = apply(input, relation_table_being_queried, query, inverse_clause, key_2)
        else
          nodes = apply(input, relation_table_being_queried, query, inverse_clause)
        end
      end

      if !is_refinement && has_any_refinements?
        refined_node = apply_refinements(input)
        # Count refinement will return nil because it directly modified pending relationship subquery
        nodes = nodes.and(refined_node) if refined_node
      end
      nodes
    end

    # When we need to go to another DB for the relation. We need to do a separate query to get the IDS of
    # the records matching the condition that will then be passed into the primary query.
    def handle_flat_cross_database_condition(root_model:, input:, relation_class:, relation_table_being_queried:, inverse_clause:, key_1:, key_2:)
      table = root_model.arel_table
      relational_query = relation_class.select(key_2).arel
      node = apply(input, relation_table_being_queried, relation_class, inverse_clause)
      relational_query = relational_query.where(node)
      array_of_ids = relation_class.connection.exec_query(relational_query.to_sql).rows.flatten
      if array_of_ids.length == 1
        nodes = table[:"#{key_1}"].eq(array_of_ids.first)
      else
        nodes = table[:"#{key_1}"].in(array_of_ids)
      end
    end

    def get_through_reflection(instance:, relation:)
      if instance.is_a? ActiveRecord::Reflection::ThroughReflection
        through_reflection = instance.through_reflection
        instance.active_record_primary_key.to_sym
        if(through_reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection))
          through_reflection = instance.source_reflection.through_reflection
        end
        through_reflection
      else
        puts "Not a through Reflection: #{instance.inspect}"
      end
    end

    def get_foreign_key_from_relation(instance:, reflection:)
      child_foreign_key = instance.source_reflection.foreign_key
      child_foreign_key
    end

    def add_pending_join(joins_array:, join_type: :inner, on_condition:, through_reflection: nil)
      current_model = filter.model
      left_table = current_model.arel_table
      filter.needs_distinct = true

      joins_array.each_with_index do |relation, idx|
        puts "Applying Join chain: #{relation} - #{idx} - #{current_model}"
        reflection = current_model.reflect_on_association(relation.to_sym)
        raise "Association #{relation} not found on #{current_model}" unless reflection

        base_table = reflection.klass.table_name
        filter.pending_joins[base_table] ||= { count: 0, nodes: [], aliased_nodes: [] joins_block: nil }
        filter.pending_joins[base_table][:count] += 1
        join_count = filter.pending_joins[base_table][:count]
        alias_name = "#{base_table}_#{join_count}"
        right_table = Arel::Table.new(base_table).alias(alias_name)

        # Determine join keys
        parent_key = reflection.active_record_primary_key
        foreign_key = reflection.foreign_key

        # The child table (right_table) always has the foreign key
        bridge_condition = right_table[foreign_key].eq(left_table[parent_key])

        # Only apply on_condition to the last join
        full_condition = if idx == joins_array.length - 1 && on_condition
          bridge_condition.and(on_condition)
        else
          bridge_condition
        end

        join_class = join_type == :left ? Arel::Nodes::OuterJoin : Arel::Nodes::InnerJoin
        if left_table.is_a?(Arel::Nodes::TableAlias)
          join_node = Arel::Nodes::InnerJoin.new(
            left_table,
            Arel::Nodes::On.new(
              left_table[parent_key].eq(right_table[foreign_key])
            ).on(full_condition)
            .join_sources
          )
        else
          join_node = left_table.join(right_table, join_class)
                          .on(full_condition)
                          .join_sources
        end

        filter.pending_joins[base_table][:nodes] << join_node

        # Prepare for next iteration
        left_table = right_table
        current_model = reflection.klass
      end

      # Should return nil because we've already added the condition to the query and do not need to add it later
      nil
    end

    def add_pending_joins_if_needed(input:, joins_array:, on_condition: nil, through_reflection: nil)
      # Determine if we need to do left-joins due to the clause needing to include null values
      join_type = (input && LEFT_JOIN_CLAUSES.include?(input[:clause])) ? :left : :inner
      add_pending_join(joins_array: joins_array, join_type: join_type, on_condition: on_condition, through_reflection: through_reflection)
    end

    def condition_uses_different_database?(current_model, parent_model)
      # Are the queries on different databases?
      parent_model.connection_db_config.configuration_hash != current_model.connection_db_config.configuration_hash
    end
    
  end
end