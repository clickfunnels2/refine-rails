module Hammerstone::Refine::Conditions
  module UsesAttributes
    def with_attribute(value)
      @attribute = value
      self
    end

    def apply_relationship_attribute(input:, query:)
      # Split on first .
      decompose_attribute = @attribute.split(".", 2)
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
      instance = if query.respond_to? :model
        query.model.reflect_on_association(relation.to_sym)
      else
        # When query is sent in as subquery (recursive) the query object is the model class pulled from the
        # previous instance value
        query.reflect_on_association(relation.to_sym)
      end

      raise "Relationship does not exist for #{relation}. Did you mistakenly configure your filter to use the plural form?" unless instance

      filter.set_pending_relationship(relation, instance)

      if can_use_where_in_relationship_subquery?(instance)
        create_pending_wherein_subquery(input: input, relation: relation, instance: instance, query: query)
      else
        create_pending_has_many_through_subquery(input: input, relation: relation, instance: instance, query: query)
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

    def create_pending_wherein_subquery(input:, relation:, instance:, query:)
      query_class = instance.klass

      subquery_table = instance.klass.arel_table

      subquery = filter.get_pending_relationship_subquery || subquery_table.project(subquery_table[key_2(instance).to_s])
      filter.add_pending_relationship_subquery(subquery: subquery, primary_key: key_1(instance), secondary_key: key_2(instance))
      # Apply condition scoped to existing subquery
      apply_and_add_to_query(query_class: query_class, table: subquery_table, input: input, subquery: subquery)
    end

    def apply_and_add_to_query(query_class:, table:, input:, subquery:)
      node = apply(input, table, query_class)
      # This modifies the object in pending relationship subqueries when given an AREL node
      if node
        subquery.where(node)
      else
        node
      end
    end

    def create_pending_has_many_through_subquery(input:, relation:, instance:, query:)
      # Ex: A country has many posts through hmtt_users.
      # If querying posts from countries, the instance
      # is a through reflection with a name of posts

      # We can get the through class using the through_reflection method, get the class, and
      # convert to an AREL table
      # In a typical HMT relationship, instance.through_reflection is a HasManyReflection

      # hmtt_users table
      through_table = instance.through_reflection.klass.arel_table

      query_class = instance.klass
      # Keys to join users and countries
      through_primary_key = instance.through_reflection.join_primary_key.to_sym # country_id
      through_foreign_key = instance.through_reflection.join_foreign_key # id

      # Keys to join users and posts
      join_primary = instance.join_primary_key.to_sym # hmtt_user_id
      join_foreign = instance.join_foreign_key.to_sym # id

      # posts table
      subquery_table = instance.klass.arel_table

      # base select manager
      base_select = through_table.project(through_table[through_primary_key])

      second_join = through_table[join_foreign].eq(subquery_table[join_primary])

      subquery = filter.get_pending_relationship_subquery || base_select.join(subquery_table).on(second_join)

      filter.add_pending_relationship_subquery(subquery: subquery, primary_key: through_foreign_key, secondary_key: nil)

      apply_and_add_to_query(query_class: query_class, table: subquery_table, input: input, subquery: subquery)
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
