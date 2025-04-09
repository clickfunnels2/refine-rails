# This module is meant to provide an alternative to #get_query which will attempt to make the query flat with inner and left joins
# instead of nested queries. This is useful for performance reasons when the query is complex and the database is large.
# NOTE: This is more specialized query construction and it is up to the implementer to use the inspector tools to ensure this is only being used for supported queries
module Refine
  module FlatQueryTools
    attr_accessor :pending_joins, :applied_conditions, :needs_distinct

    def pending_joins
      @pending_joins ||= {}
    end

    def applied_conditions
      @applied_conditions ||= {}
    end

    def needs_distinct?
      @needs_distinct ||= false
    end

    def should_use_flat_query?
      # Defaults to false. Implementing filter classes should override this to enable flat_query
      false
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
      blueprint.each do |criteria_or_conjunction|
        if criteria_or_conjunction[:type] == "conjunction"
          if criteria_or_conjunction[:word] == "or"
            puts "This is an OR"
            # Reset applied conditions since we're in a new group
            @applied_conditions = {}
          end
        else
          unless condition_already_applied?(criteria_or_conjunction)
            node = apply_flat_condition(criteria_or_conjunction)
            @relation = @relation.where(Arel.sql(node.to_sql))
            track_condition_applied(criteria_or_conjunction)
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
        get_condition_for_criterion(criterion)&.apply_flat(criterion[:input], table, initial_query, false)
      rescue Refine::Conditions::Errors::ConditionClauseError => e
        e.errors.each do |error|
          errors.add(:base, error.full_message, criterion_uid: criterion[:uid])
        end
      end
    end

    # Called at the end of the filter's construct_flat_query. Applies joins from pending_joins hash constructed by individual conditions
    def apply_pending_joins
      if pending_joins.present?
        join_count = 0
        pending_joins.each do |relation, join_data|
          if join_data[:type] == :left
            @relation = @relation.left_joins(join_data[:joins_block]).distinct
          else
            @relation = @relation.joins(join_data[:joins_block]).distinct
          end
          join_count += 1
        end

      end
    end

    def track_condition_applied(criterion)
      if applied_conditions[criterion[:condition_id]].nil?
        applied_conditions[criterion[:condition_id]] = [criterion[:input]]
      else
        applied_conditions[criterion[:condition_id]] << criterion[:input]
      end
    end

    def condition_already_applied?(criterion)
      applied_conditions[criterion[:condition_id]] && 
        applied_conditions[criterion[:condition_id]].include?(criterion[:input])
    end
  end
end