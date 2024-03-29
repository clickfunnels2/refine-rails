module Refine::Conditions
  class BooleanCondition < Condition
    include HasClauses

    CLAUSE_TRUE = Clauses::TRUE
    CLAUSE_FALSE = Clauses::FALSE
    CLAUSE_SET = Clauses::SET # non null
    CLAUSE_NOT_SET = Clauses::NOT_SET # null

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
      without_clauses([
        CLAUSE_SET,
        CLAUSE_NOT_SET,
      ])
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
      with_clauses([
        CLAUSE_SET,
        CLAUSE_NOT_SET
      ])
      self
    end

    def clauses
      [
        Clause.new(CLAUSE_TRUE, I18n.t("#{I18N_PREFIX}is_true")),
        Clause.new(CLAUSE_FALSE, I18n.t("#{I18N_PREFIX}is_false")),
        Clause.new(CLAUSE_SET, I18n.t("#{I18N_PREFIX}is_set")),
        Clause.new(CLAUSE_NOT_SET, I18n.t("#{I18N_PREFIX}is_not_set")),
      ]
    end

    def apply_condition(_input, table, _inverse_clause)
      case clause
      when CLAUSE_SET
        apply_clause_set(table)

      when CLAUSE_NOT_SET
        apply_clause_not_set(table)

      when CLAUSE_TRUE
        apply_clause_true(table)

      when CLAUSE_FALSE
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
