module Hammerstone::Refine::Conditions
  module HasRefinements
    def refine_by_date(callable = nil)
      # Developer can send in a string that represents the attribute or a proc that is a fully qualified class
      # If a callable is given and it is a string, we assume that is the desired attribute. Otherwise we use
      # the passed in callable. If no callable is given we create on based on standard date with time condition
      @date_refinement_proc = if callable.present?
        (callable.is_a? String) ? define_date_condition(attribute: callable) : callable
      else
        define_date_condition(attribute: "created_at")
      end
      self
    end

    def define_date_condition(attribute:)
      proc { DateCondition.new("date_refinement").with_attribute(attribute).attribute_is_date_with_time }
    end

    def refine_by_count(callable = nil)
      @count_refinement_proc = callable.present? ? callable : define_count_condition
      self
    end

    def define_count_condition
      proc { NumericCondition.new("count_refinement") }
    end

    def apply_refinements(input)
      if has_any_refinements? && !refinements_allowed?
        raise Errors::RelationshipError, "Refinements are not allowed"
      end

      instance = filter.get_pending_relationship_instance
      subquery_table = instance.klass.arel_table
      subquery = filter.get_pending_relationship_subquery

      if @date_refinement_proc
        nodes = apply_date_refinement(subquery_table, input[:date_refinement])
      end
      if @count_refinement_proc
        apply_count_refinement(table: subquery_table, input: input[:count_refinement], subquery: subquery, instance: instance)
      end
      nodes
    end

    def has_any_refinements?
      @date_refinement_proc || @count_refinement_proc ? true : false
    end

    def refinements_allowed?
      instance = filter.get_pending_relationship_instance
      (instance.is_a? ActiveRecord::Reflection::HasManyReflection) || (instance.is_a? ActiveRecord::Reflection::ThroughReflection)
    end

    def apply_date_refinement(table, input)
      get_date_refinement_condition.apply(input, table, nil)
    end

    def apply_count_refinement(table:, input:, subquery:, instance:)
      # We need to group by because we're going to be using a `having`
      # to get the count of records. Since we're using a where in for this
      # relationship subquery, we're only selecting the foreign key,
      # so we'll just group by that too.
      condition = get_count_refinement_condition
      node = condition.apply(input, table, nil)
      # Modify the pending relationship subquery in place to be applied later
      # Remember, AREL in this instance has passed by reference so pending_relationship_subquery will be modified
      subquery.group(table[instance.foreign_key]).having(node)
      # Return nil case due to pending relationship subquery not yet being applied
      nil
    end

    def get_date_refinement_condition
      # Create the condition from the callable
      condition = @date_refinement_proc.call
      # Overwrite any passed in id's with date_refinement
      condition.id = "date_refinement"
      condition.is_refinement = true
      filter.instantiate_condition(condition)
    end

    def get_count_refinement_condition
      condition = @count_refinement_proc.call
      # Overwrite any passed in id's with count_refinement
      condition.id = "count_refinement"
      condition.is_refinement = true
      filter.instantiate_condition(condition)
    end

    def refinements_to_array
      if is_refinement
        []
      else
        refinement_array = []
        if @date_refinement_proc
          refinement_array << get_date_refinement_condition.to_array
        end
        if @count_refinement_proc
          refinement_array << get_count_refinement_condition.to_array
        end
        refinement_array
      end
    end
  end
end
