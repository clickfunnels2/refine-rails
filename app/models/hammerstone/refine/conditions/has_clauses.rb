module Hammerstone::Refine::Conditions
  module HasClauses

    def boot_has_clauses
      add_rules({ clause: "required" })
      with_meta({ clauses: get_clauses })
      @show_clauses = {}
    end

    #beforeValidationOfClause in PHP callback land
    def add_clause_rules_to_condition(input)
      current_clause = clauses.select{ |clause| clause.id == input[:clause] }
      if current_clause.present?
        add_rules(current_clause[0].rules)
      end
    end

    def custom_clauses
      []
    end

    def only_clauses(specific_clauses)
      clauses.map(&:id).each {|clause_id| update_show_clauses(clause_id, false) }
      specific_clauses.each {|clause| update_show_clauses(clause, true) }
      self
    end

    def with_clauses(clauses_to_include)
      clauses_to_include.each {|clause| update_show_clauses(clause, true) }
      self
    end

    def without_clauses(clauses_to_exclude)
      clauses_to_exclude.each {|clause| update_show_clauses(clause, false) }
      self
    end

    def update_show_clauses(clause, value)
      @show_clauses.merge!({"#{clause}": value})
    end

    def validate_clause(clause)
      if !clause.is_a? Clause
        errors.add(:base, "Every clause must be an instance of #{Clause::class}")
        raise Errors::ConditionClauseError, "#{errors.full_messages}"
      end
      if clause.id.blank? || clause.display.blank?
        errors.add(:base, "A clause must have both id and display keys")
        raise Errors::ConditionClauseError, "#{errors.full_messages}"
      end
    end

    def get_clauses
      Proc.new do
        clauses.each do |clause|
          validate_clause(clause)
        end

        returned_clauses = clauses.dup

        @show_clauses.each do |clause_id, rule|
          filterable_clause_index = returned_clauses.index{ |clause| clause.id.to_sym == clause_id }
          if rule == false
            returned_clauses.delete_at(filterable_clause_index)
          elsif rule == true
            add_clause = returned_clauses.find{|clause| clause.id.to_sym == clause_id }
            returned_clauses << add_clause if !add_clause
          end
        end
        returned_clauses
      end
    end
  end
end