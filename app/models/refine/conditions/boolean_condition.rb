module Refine::Conditions
  class BooleanCondition < Condition
    include HasClauses

    I18N_PREFIX = "refine.refine_blueprints.boolean_condition."

    def component
      "boolean-condition"
    end

    def human_readable(input)
      current_clause = get_clause_by_id(input[:clause])
      if input[:value]
        "#{display} #{current_clause.display} #{input[:value]}"
      else
        "#{display} #{current_clause.display}"
      end
    end

    def boot
      @nulls_are = nil
      hide_unknowns
    end

    def hide_unknowns
      without_presence_clauses
      self
    end

    def nulls_are_true
      @nulls_are = true
      self
    end

    def nulls_are_false
      @nulls_are = false
      self
    end

    def nulls_are_unknown
      @nulls_are = nil
      self
    end

    def show_unknowns
      with_clauses(:set, :not_set)
      self
    end

    def clauses
      [
        Clause.new(Clauses::TRUE, I18n.t("#{I18N_PREFIX}is_true")),
        Clause.new(Clauses::FALSE, I18n.t("#{I18N_PREFIX}is_false")),
        Clause.new(Clauses::SET, I18n.t("#{I18N_PREFIX}is_set")),
        Clause.new(Clauses::NOT_SET, I18n.t("#{I18N_PREFIX}is_not_set")),
      ]
    end

    def apply_condition(_input, table, _inverse_clause)
      case clause
      when Clauses::SET
        apply_clause_set(table)

      when Clauses::NOT_SET
        apply_clause_not_set(table)

      when Clauses::TRUE
        apply_clause_true(table)

      when Clauses::FALSE
        apply_clause_false(table)
      end

      # Apply a custom clause
    end

    def apply_clause_set(table)
      table.grouping(table[:"#{attribute}"].not_eq(nil))
    end

    def apply_clause_not_set(table)
      table.grouping(table[:"#{attribute}"].eq(nil))
    end

    def apply_clause_true(table)
      apply_clause_bool(table, true)
    end

    def apply_clause_bool(table, bool)
      if @nulls_are == bool
        table.grouping(table[:"#{attribute}"].eq(bool).or(table[:"#{attribute}"].eq(nil)))
      else
        table.grouping(table[:"#{attribute}"].eq(bool))
      end
    end

    def apply_clause_false(table)
      apply_clause_bool(table, false)
    end
  end
end
