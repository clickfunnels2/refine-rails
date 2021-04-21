module Hammerstone::Refine::Conditions
  module UsesAttributes

    def with_attribute(value)
      @attribute = value
      self
    end

    def apply_relationship_attribute(input:, query:)
      decompose_attribute = @attribute.split(".", 2) # Split on first .
      # Relation to be handled
      relation = decompose_attribute[0]
      # Attribute now is the back half of the initial attribute
      @attribute = decompose_attribute[1]

      if !@attribute.include?(".")
        # No more .s, deepest level
        @on_deepest_relationship = true
      end

      # Get the Reflection object aka the relationship.
      # First iteration pull relationship using base query which responds to model.
      if query.respond_to? :model
        instance = query.model.reflect_on_association(relation.to_sym)
      else
        # When query is sent in as subquery (recursive) the query object is the model class pulled from the
        # previous instance value
        instance = query.reflect_on_association(relation.to_sym)
      end

      raise "Relationship does not exist for #{relation}" if !instance

      filter.set_pending_relationship(relation, instance)

      if can_use_where_in_relationship_subquery?(instance)
        create_pending_wherein_subquery(input: input, relation: relation, instance: instance, query: query)
      else
        #do wherehas
      end
      filter.release_pending_relationship
      # This is an odd case where we want the method to return nil for relationship attributes
      # The purpose of this method is to populate pending relationship subqueries
      nil
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


    def create_pending_wherein_subquery(input:, relation:, instance:, query: )
      query_class = instance.klass
      subquery_table = instance.klass.arel_table

      if filter.get_pending_relationship_subquery
        subquery = filter.get_pending_relationship_subquery
      else
        subquery = subquery_table.project(subquery_table["#{key_2(instance)}"])
      end

      filter.add_pending_where_in_relationship_subquery(subquery: subquery, primary_key: key_1(instance), secondary_key: key_2(instance))

      if apply_in_nested_where(query_class: query_class, table: subquery_table, input: input)
        subquery.where(apply_in_nested_where(query_class: query_class, table: subquery_table, input: input))
      else
        apply_in_nested_where(query_class: query_class, table: subquery_table, input: input)
      end
    end

    def apply_in_nested_where(query_class:, table:, input:)
      apply(input, table, query_class) #this apply returns nil
    end

    def create_where_in(input:, relation:, table:, instance:, query:)
      #Revisit
    end


    def can_use_where_in_relationship_subquery?(instance)
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