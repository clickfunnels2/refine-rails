# This module is meant to provide an alternative to #get_query which will attempt to make the query flat with inner and left joins
# instead of nested queries. This is useful for performance reasons when the query is complex and the database is large.
# NOTE: This is more specialized query construction and it is up to the implementer to use the inspector tools to ensure this is only being used for supported queries
module Refine
  module FlatQueryTools
    attr_accessor :pending_joins, :applied_conditions, :needs_distinct, :condition_counts

    def pending_joins
      @pending_joins ||= {}
    end

    def condition_counts
      @condition_counts ||= {}
    end

    def needs_distinct?
      @needs_distinct ||= false
    end

    def get_flat_query
      raise "Initial query must exist" if initial_query.nil?
      raise "Cannot make flat query for a filter using OR conditions" if uses_or?
      if blueprint.present?
        construct_flat_query
      else
        @relation
      end
    end

    def get_flat_query!
      result = get_flat_query
      raise Refine::InvalidFilterError.new(filter: self) unless errors.none?
      result
    end

    # This iterates through each blueprint item and applies the conditions.
    # It is meant to be idempotent hence it checks for already applied conditions
    def construct_flat_query
      groups = []
      build_condition_counts
      blueprint.each do |criteria_or_conjunction|
        if criteria_or_conjunction[:type] == "conjunction"
          if criteria_or_conjunction[:word] == "or"
            puts "This is an OR"
            # Reset applied conditions since we're in a new group
            @applied_conditions = {}
          end
        else
          node = apply_flat_condition(criteria_or_conjunction)
          if node
            @relation = @relation.where(node)
          end
        end
      end
      if pending_joins.present?
        apply_pending_joins
      end
      if needs_distinct?
        @relation = @relation.distinct
      end
      @relation
    end

    # Same as Filter.apply_condition but uses `supports_flat_queries` helpers instead of default path
    def apply_flat_condition(criterion)
      begin
        condition = get_condition_for_criterion(criterion)
        condition&.apply_flat(criterion[:input], table, initial_query, false, should_apply_condition_on_join?(condition))
      rescue Refine::Conditions::Errors::ConditionClauseError => e
        e.errors.each do |error|
          errors.add(:base, error.full_message, criterion_uid: criterion[:uid])
        end
      end
    end

    # Called at the end of the filter's construct_flat_query. Applies joins from pending_joins hash constructed by individual conditions
    # If the same joins occurs twice, we need to apply the extra clauses to the joins AND use aliases
    def apply_pending_joins
      return if pending_joins.blank?
    
      pending_joins.each_value do |data|
        if data[:count] > 1
          data[:nodes].each do |join_node_array|
            join_node_array.each do |join_node|
              puts "Applying join node: #{join_node} for dupe"
              @relation = @relation.joins(join_node).distinct
            end
          end
        else
          if data[:joins_block].present?
            puts "Applying joins block: #{data[:joins_block]} - single"
            @relation = @relation.joins(data[:joins_block]).distinct
          else
            puts "Applying join node: #{data[:nodes]} - single"
            @relation = @relation.joins(data[:nodes]).distinct
          end
        end
      end
    end

    def build_condition_counts
      blueprint.each do |criterion_or_conjunction|
        if criterion_or_conjunction[:type] == "criterion"
          increment_condition_count(get_condition_for_criterion(criterion_or_conjunction))
        end
      end
    end

    def increment_condition_count(condition_object)
      condition_counts[condition_object.attribute] ||= 0
      condition_counts[condition_object.attribute] += 1
    end

    def should_apply_condition_on_join?(condition_object)
      return false if condition_counts[condition_object.attribute].blank?
      condition_counts[condition_object.attribute] > 1
    end
  end
end