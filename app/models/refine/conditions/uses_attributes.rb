module Refine::Conditions
  module UsesAttributes

    def with_attribute(value)
      @attribute = value
      self
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

      use_joins = true
      if use_joins
        puts "Need to use joins"
        puts "Query: #{query.to_sql}"
        puts "Input: #{input}"
        puts "Relation: #{relation}"
        puts "Instance: #{instance}"
        if self.through_id_relationship
          if instance.is_a? ActiveRecord::Reflection::ThroughReflection
            through_reflection = instance.through_reflection
            if(through_reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection))
              through_reflection = instance.source_reflection.through_reflection
            end
            parent_foreign_key = through_reflection.foreign_key
            child_foreign_key = instance.source_reflection.foreign_key
            relation_table_being_queried = through_reflection.klass.arel_table
            relation_class = through_reflection.klass
            through_relation = instance.through_reflection.name
            relation_class = instance.through_reflection.klass
            puts "THROUGH Relation: #{relation_class}"
            puts "relation_class_table: #{relation_class.arel_table}"
            puts "parent_foreign_key: #{parent_foreign_key}"
            puts "child_foreign_key: #{child_foreign_key}"
            node = apply(input, relation_class.arel_table, relation_class, false, child_foreign_key)
          end
        else
          relation_class = instance.klass
          node = apply(input, relation_class.arel_table, relation_class, false)
        end
        puts "Updated Nodes: #{node.to_sql}"
        return node
      else
        filter.set_pending_relationship(relation, instance)
        
        # If the current condition is a refinement (filter refinement) set collapsible to true 
        if is_refinement
          filter.allow_pending_relationship_to_collapse
        end

        if can_use_where_in_relationship_subquery?(instance)
          create_pending_wherein_subquery(input: input, relation: relation, instance: instance, query: query)
        else
          create_pending_has_many_through_subquery(input: input, relation: relation, instance: instance, query: query)
        end

        filter.release_pending_relationship
      end
      # We want the method to return nil for relationship attributes
      # The purpose of this method is to populate pending relationship subqueries
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

      # Primary/secondary keys keep track of how to link tables
      # If depth has been added (i.e. filter.pending_relationship_subquery_depth = [:btt_user, :btt_notes])
      # This will add the [:children] key to the pending_relationship_subqueries tracker under the parent key [:btt_user]
      filter.add_pending_relationship_subquery(subquery: subquery, primary_key: key_1(instance), secondary_key: key_2(instance))

      # Apply the condition. If a nested relationship, this apply is adding the children key (with values) to the pending_relationship_subqueries tracker
      # due to the recursive nature of the apply method. This is critical because it get is then "rolled up" in release_pending_relationship
      node = apply(input, relation_class.arel_table, relation_class, false)

      # If node is an AREL::SELECT manager we are allowing the apply condition to return a fully formed subquery - we replace
      # the linking keys in the tracker with the fully formed select query
      # Has not been tested more than one level deep
      if node.is_a? Arel::SelectManager
        filter.add_pending_relationship_subquery(subquery: node, primary_key: key_1(instance), secondary_key: key_2(instance))
      elsif node
        # This modifies subquery *in* the pending_relationship_subqueries tracker.
        subquery.where(node)
      end
    end

    def group(nodes)
      Arel::Nodes::Grouping.new(nodes)
    end

    # Determine if the clause should be flipped. For example, "not_eq" => "eq". Must also change "in" to "not in" upstream
    # @param [Object] instance
    # @param [String] clause The join clause (example: `eq` or `not_eq`)
    # @return [Boolean]
    def should_inverse_clause?(instance, clause)
      is_through_reflection = instance.is_a?(ActiveRecord::Reflection::ThroughReflection)
      is_inverse_clause_flippable = Clauses::FLIPPABLE.include?(clause)

      is_through_reflection && is_inverse_clause_flippable
    end

    def create_pending_has_many_through_subquery(input:, relation:, instance:, query:)
      # In a has_many relationship the negative has to be flipped to positive. 
      inverse_clause = should_inverse_clause?(instance, input[:clause])
      # Ex: A country has many posts through hmtt_users.
      # Use AR to properly join the relation to the base query provided
      # Convert to AREL to use with nodes 
      subquery_path = query.model.select(key_1(instance)).joins(relation.to_sym).arel
      relation_table_being_queried = instance.klass.arel_table

      relation_class = instance.klass

      if self.through_id_relationship
        if instance.is_a? ActiveRecord::Reflection::ThroughReflection
          through_reflection = instance.through_reflection
          if(through_reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection))
            through_reflection = instance.source_reflection.through_reflection
          end
          parent_foreign_key = through_reflection.foreign_key
          child_foreign_key = instance.source_reflection.foreign_key
          relation_table_being_queried = through_reflection.klass.arel_table
          relation_class = through_reflection.klass
          if(through_reflection.chain.count > 1)
            # We need to shortcut the outer inner joins but allow the others to go as normal
            parent_foreign_key = through_reflection.chain.last.foreign_key
            parent_through_reflection = through_reflection.chain.last
            join_sym = through_reflection.source_reflection_name
            subquery_path = parent_through_reflection.klass.select(parent_foreign_key).joins(join_sym)
            if(through_reflection.scope && through_reflection.scope.is_a?(Proc))
              subquery_path = subquery_path.instance_exec(&through_reflection.scope)
            end
            subquery_path = subquery_path.arel
          else
            # Does not need any inner joins
            subquery_path = through_reflection.klass.select(parent_foreign_key).arel
          end
         
          node_to_apply = apply(input, relation_table_being_queried, relation_class, inverse_clause, child_foreign_key)
        else
          raise Refine::Conditions::Errors::RelationshipError.new("with_through_id must be used with a has_many :through relationship")
        end
      else
        node_to_apply = apply(input, relation_table_being_queried, relation_class, inverse_clause)
      end

      if self.forced_index
        mysql_from_segment = "`#{through_reflection.table_name}` FORCE INDEX(`#{self.forced_index}`)"
        # Ensuring input is sanitized
        subquery_path = subquery_path.from(Arel.sql(mysql_from_segment))
      end
      
      complete_subquery = subquery_path.where(node_to_apply)
      subquery = filter.get_pending_relationship_subquery || complete_subquery
      filter.add_pending_relationship_subquery(subquery: subquery, primary_key: key_1(instance), secondary_key: nil, inverse_clause: inverse_clause)
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

      self
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
