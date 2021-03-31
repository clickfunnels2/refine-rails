module Hammerstone::Refine::Conditions
  module UsesAttributes

    def with_attribute(value)
      @attribute = value
      self
    end

    def apply_relationship_attribute(input:, table:, query:)
      decompose_attribute = @attribute.split(".", 2) # Split on first .

      relation = decompose_attribute[0]
      # Attribute now is the back half of the initial attribute
      @attribute = decompose_attribute[1]

      if !@attribute.include?(".")
        # No more .s, deepest level
        @on_deepest_relationship = true
      end

      # Get the Reflection object aka the relationship.
      # First iteration pull relationship using base query which responds to model
      if query.respond_to? :model
        instance = query.model.reflect_on_association(relation.to_sym)
      else
        # When query is sent in as subquery the query object is the model pulled from the
        # previous instance value
        instance = query.reflect_on_association(relation.to_sym)
      end
      raise "Relationship does not exist for #{attribute_to_array[0]}" if !instance

      filter.set_pending_relationship(relation, instance)

      if can_use_where_in?(instance)
        create_pending_wherein_subquery(input: input, relation: relation, table: table, instance: instance, query: query)
      else
        #do wherehas
      end
    end

      def key_1(instance)
        # Foreign key on belongs to, primary key on HasMany
        if instance.is_a? ActiveRecord::Reflection::BelongsToReflection
          instance.foreign_key.to_sym
        else
          instance.active_record.primary_key.to_sym
        end
      end

      def key_2(instance)
        if instance.is_a? ActiveRecord::Reflection::BelongsToReflection
          instance.active_record.primary_key.to_sym
        else
          instance.foreign_key.to_sym
        end
      end


    def create_pending_wherein_subquery(input:, relation:, table:, instance:, query: )
      # Grabs class that will be class to be queried at this level
      # If @attribute is initially user.notes.body this grabs user on iteration 1, notes on iteration 2
      # The query_class will be User, and the subquery_table will be arel_table for User

      if filter.get_pending_relationship_subquery
        subquery = filter.get_pending_relationship_subquery
      else
        subquery = create_where_in(input: input, relation: relation, table: table, instance: instance, query: query)
      end

      query_class = instance.klass
      subquery_table = instance.klass.arel_table

      # Build the select to return only what we need
      # The keys change depending on the type of relationship
      recursive_apply = apply(input, subquery_table, query_class)

      select_manager = subquery_table.project(subquery_table["#{key_2(instance)}"])

      table["#{ key_1(instance)}"].in(select_manager.where(recursive_apply))
    end

    def create_where_in(input:, relation:, table:, instance:, query:)
    end


    def can_use_where_in?(instance)
      # Where in only works for belongs to, has one, or has many
      (instance.is_a? ActiveRecord::Reflection::BelongsToReflection) || (instance.is_a? ActiveRecord::Reflection::HasManyReflection) || (instance.is_a? ActiveRecord::Reflection::HasOneReflection)
    end

    def is_relationship_attribute?
      # TODO: Allow user to decide attribute is not a relationship
      # If we are on the deepest relationship, it's no longer a relationship attribute
      return false if @on_deepest_relationship
      # If the attribute includes a ., it's a relationship attribute
      @attribute.include?(".")
    end

  end
end