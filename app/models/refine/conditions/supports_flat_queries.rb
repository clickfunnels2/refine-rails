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
    # @return [Arel::Node] 
    # This is mostly a copy of the `apply` method from the Condition module, but avoids recursion and the pending_subquery system
    def apply_flat(input, table, initial_query, inverse_clause=false)
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
        # TODO - Handle refinements. Currently not working for flat queries because its dependent on the pending_subquery system

        filter_condition = call_proc_if_callable(@filter_refinement_proc)
        # Set the filter on the filter_condition to be the current_condition's filter
        filter_condition.set_filter(filter)
        filter_condition.is_refinement = true

        # Applying the filter condition will modify pending relationship subqueries in place
        filter_condition.apply(input.dig(:filter_refinement), table, initial_query)
        input.delete(:filter_refinement)
      end

      if is_relationship_attribute?
        return handle_flat_relational_condition(input: input, table: table, query: initial_query, inverse_clause: inverse_clause)
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

    def handle_flat_relational_condition(input:, table:, query:, inverse_clause:)
      # Split on first .
      decompose_attribute = @attribute.split(".", 2)
      # Attribute now is the back half of the initial attribute
      @attribute = decompose_attribute[1]
      # Relation to be handled
      relation = decompose_attribute[0]

     
      # Get the Reflection object which defines the relationship between query and relation
      # First iteration pull relationship using base query which responds to model.
      instance = if query.respond_to? :model
        query.model.reflect_on_association(relation.to_sym)
      else
        # When query is sent in as subquery (recursive) the query object is the model class pulled from the
        # previous instance value
        query.reflect_on_association(relation.to_sym)
      end

      through_reflection = instance
      forced_id = false

      # TODO - make sure we're accounting for refinements
      if @attribute == "id"
        # We're referencing a primary key ID, so we dont need the final join table and
        # can just reference the foreign key of the previous step in the relation chain
        through_reflection = get_through_reflection(instance: instance, relation: decompose_attribute[0])
        unless condition_uses_different_database?(through_reflection.klass, query.model)
          forced_id = true
          @attribute = get_foreign_key_from_relation(instance: instance, reflection: through_reflection)
        end
      end

      unless condition_uses_different_database?(through_reflection.klass, query.model)
        add_pending_joins_if_needed(instance: instance, reflection: through_reflection, input: input)
      end
      # TODO - this is not the right long-term place for this.
      apply_flat_relational_condition(instance: instance, relation: relation, through_reflection: through_reflection, input: input, table: table, query: query, inverse_clause: inverse_clause, forced_id: forced_id)
    end

    def apply_flat_relational_condition(instance:, relation:, through_reflection:, input:, table:, query:, inverse_clause:, forced_id: nil)
      unless instance
        raise "Relationship does not exist for #{relation}."
      end

      relation_table_being_queried = through_reflection.klass.arel_table
      relation_class = through_reflection.klass

      instance = get_reflection_object(query, relation) if forced_id

      key_1 = key_1(instance)
      key_2 = key_2(instance)
      if condition_uses_different_database?(relation_class, query.model)
        nodes = handle_flat_cross_database_condition(input: input, table: table, relation_class: relation_class, relation_table_being_queried: relation_table_being_queried, inverse_clause: inverse_clause, key_1: key_1, key_2: key_2)  
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
    def handle_flat_cross_database_condition(input:, table:, relation_class:, relation_table_being_queried:, inverse_clause:, key_1:, key_2:)
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

    def add_pending_join(relation, join_type=:inner)
      # If we already are tracking the relation with a left joins, don't overwrite it
      # puts "adding a pending join for relation: #{relation} with join type: #{join_type}"
      unless join_type == :inner && filter.pending_joins[relation] == :left
        filter.needs_distinct = true
        filter.pending_joins[relation] = join_type
      end
    end

    def add_pending_joins_if_needed(instance:, reflection:, input:)
      # Determine if we need to do left-joins due to the clause needing to include null values
      if(input && LEFT_JOIN_CLAUSES.include?(input[:clause]))
        add_pending_join(reflection.name, :left)
      else
        add_pending_join(reflection.name, :inner)
      end
    end

    def condition_uses_different_database?(current_model, parent_model)
      # Are the queries on different databases?
      parent_model.connection_db_config.configuration_hash != current_model.connection_db_config.configuration_hash
    end
  end
end