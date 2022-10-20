module Hammerstone::Refine::Conditions
  module UsesAttributes

    def with_attribute(value)
      @attribute = value
      self
    end

    def apply_and_add_to_query(query_class:, table:, input:, subquery:, flip_option_condition: false)
      node = apply(input, table, query_class, flip_option_condition)
      if node
        subquery.where(node)
      else
        node
      end
    end

    def apply_relationship_attribute(input:, query:)
      # Split on first .
      decompose_attribute = @attribute.split(".", 2)
      # Attribute now is the back half of the initial attribute
      @attribute = decompose_attribute[1]

      if !@attribute.include?(".")
        # No more .s, deepest level
        @on_deepest_relationship = true
      end
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

      unless instance
        raise "Relationship does not exist for #{relation}."
      end

      filter.set_pending_relationship(relation, instance)
      
      # If the current condition is a refinement (filter refinement) set collapsible to true 
      if is_refinement
        filter.allow_pending_relationship_to_collapse
      end

      if can_use_where_in_relationship_subquery?(instance)
        create_pending_wherein_subquery(input: input, relation: relation, instance: instance, query: query)
      else
        # TODO ERIC -> I need to see all the possible relationships that are a "has many". Is it only through reflection?
        create_pending_has_many_through_subquery(input: input, relation: relation, instance: instance, query: query)
      end

      filter.release_pending_relationship
      # We want the method to return nil for relationship attributes
      # The purpose of this method is to populate pending relationship subqueries
      byebug
      nil
    end

    def key_1(instance)
      # Foreign key on belongs to, primary key on HasMany
      if instance.is_a? ActiveRecord::Reflection::BelongsToReflection
        instance.foreign_key.to_sym
      else
        instance.active_record_primary_key.to_sym
      end
    end

    def key_2(instance)
      if instance.is_a? ActiveRecord::Reflection::BelongsToReflection
        instance.active_record_primary_key.to_sym
      else
        instance.foreign_key.to_sym
      end
    end

    def create_pending_wherein_subquery(input:, relation:, instance:, query:)
      # This method builds out the linking keys between the provided query model and the relation 
      # and saves it to pending relationship subqueries
      # Class of the relation as held in the AR::Relation object 
      relation_class = instance.klass

      # Pull what's already in the tracker at this depth if already traversed
      subquery = filter.get_pending_relationship_subquery || relation_class.select([key_2(instance)]).arel
      # Primary/secondary keys keep track of how to link workspace to parent (workspaces to contact in this example)
      # Add to tracker/does nothing if already have a value at this level
      filter.add_pending_relationship_subquery(subquery: subquery, primary_key: key_1(instance), secondary_key: key_2(instance))
      # Apply condition scoped to existing subquery
      apply_and_add_to_query(query_class: relation_class, table: relation_class.arel_table, input: input, subquery: subquery)
    end

    def group(nodes)
      Arel::Nodes::Grouping.new(nodes)
    end

    def create_pending_has_many_through_subquery(input:, relation:, instance:, query:)
      # In a has_many relationship the negative has to be flipped to positive. Only through??
      flip = (instance.is_a? ActiveRecord::Reflection::ThroughReflection) ? true : false
      # Ex: A country has many posts through hmtt_users.
      # Use AR to properly join the relation to the base query provided
      # Convert to AREL to use with nodes 
      subquery_path = query.model.select(key_1(instance)).joins(relation.to_sym).arel
      relation_table_being_queried = instance.klass.arel_table

      relation_class = instance.klass
      
      node_to_apply = apply(input, relation_table_being_queried, relation_class, flip)

      complete_subquery = subquery_path.where(node_to_apply)
      subquery = filter.get_pending_relationship_subquery || complete_subquery
      filter.add_pending_relationship_subquery(subquery: subquery, primary_key: key_1(instance), secondary_key: nil, flip: flip)
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

    def raw_attribute(attribute)
      @attribute = Arel.sql(attribute)
    end

    # TODO Examine the existing relationships and suggest model names if not instance is found 
    # def get_relationships(query)
      # if query.respond_to? :model
      #   associations = query.model.reflect_on_all_associations
      # else
      #   associations = query.reflect_on_all_associations
      # end
      # associations.map{|entry| puts entry.class, entry.foreign_key, entry.klass }
      # differences=[]
      # associations.each do association
      #   differences << String::Similarity.levenshtein_distance(relation, association )
      # end
      # differences
    # end
  end
end
