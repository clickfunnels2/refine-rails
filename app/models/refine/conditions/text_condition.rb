module Refine::Conditions
  class TextCondition < Condition
    include HasClauses

    I18N_PREFIX = "refine.refine_blueprints.text_condition."

    def component
      "text-condition"
    end

    def human_readable(input)
      current_clause = get_clause_by_id(input[:clause])
      if input[:clause].in? [Clauses.set, Clauses.not_set]
        "#{display} #{current_clause.display}"
      else
        "#{display} #{current_clause.display} #{input[:value]}"
      end
    end

    def human_readable_value(input)
      current_clause = get_clause_by_id(input[:clause])
      if input[:clause].in? [Clauses.set, Clauses.not_set]
        ""
      else
        input[:value]
      end
    end

    def clauses
      [
        Clause.new(Clauses.equals, I18n.t("#{I18N_PREFIX}is"))
          .requires_inputs(["value"]),

        Clause.new(Clauses.doesnt_equal, I18n.t("#{I18N_PREFIX}is_not"))
          .requires_inputs(["value"]),

        Clause.new(Clauses.starts_with, I18n.t("#{I18N_PREFIX}starts_with"))
          .requires_inputs(["value"]),

        Clause.new(Clauses.ends_with, I18n.t("#{I18N_PREFIX}ends_with"))
          .requires_inputs(["value"]),

        Clause.new(Clauses.doesnt_start_with, I18n.t("#{I18N_PREFIX}does_not_start_with"))
          .requires_inputs(["value"]),

        Clause.new(Clauses.doesnt_end_with, I18n.t("#{I18N_PREFIX}does_not_end_with"))
          .requires_inputs(["value"]),

        Clause.new(Clauses.contains, I18n.t("#{I18N_PREFIX}contains"))
          .requires_inputs(["value"]),

        Clause.new(Clauses.doesnt_contain, I18n.t("#{I18N_PREFIX}does_not_contain"))
          .requires_inputs(["value"]),

        Clause.new(Clauses.set, I18n.t("#{I18N_PREFIX}is_set")),

        Clause.new(Clauses.not_set, I18n.t("#{I18N_PREFIX}is_not_set"))
      ]
    end

    def apply_condition(input, table, _inverse_clause)
      value = input[:value]

      case clause
      when Clauses.equals
        apply_clause_equals(value, table)

      when Clauses.doesnt_equal
        apply_clause_doesnt_equal(value, table)

      when Clauses.starts_with
        apply_clause_starts_with(value, table)

      when Clauses.ends_with
        apply_clause_ends_with(value, table)

      when Clauses.doesnt_start_with
        apply_clause_doesnt_start_with(value, table)

      when Clauses.doesnt_end_with
        apply_clause_doesnt_end_with(value, table)

      when Clauses.contains
        apply_clause_contains(value, table)

      when Clauses.doesnt_contain
        apply_clause_doesnt_contain(value, table)

      when Clauses.set
        apply_clause_set(value, table)

      when Clauses.not_set
        apply_clause_not_set(value, table)
      end
    end

    def apply_clause_equals(value, table)
      table.grouping(arel_attribute(table).eq(value))
    end

    def apply_clause_doesnt_equal(value, table)
      table.grouping(arel_attribute(table).not_eq(value).or(arel_attribute(table).eq(nil)))
    end

    def apply_clause_starts_with(value, table)
      table.grouping(arel_attribute(table).matches("#{value}%"))
    end

    def apply_clause_ends_with(value, table)
      table.grouping(arel_attribute(table).matches("%#{value}"))
    end

    def apply_clause_contains(value, table)
      table.grouping(arel_attribute(table).matches("%#{value}%"))
    end

    def apply_clause_doesnt_contain(value, table)
      table.grouping(arel_attribute(table).does_not_match("%#{value}%").or(arel_attribute(table).eq(nil)))
    end

    def apply_clause_set(_, table)
      table.grouping(arel_attribute(table).not_eq_all([nil, ""]))
    end

    def apply_clause_not_set(_, table)
      table.grouping(arel_attribute(table).eq_any([nil, ""]))
    end

    def apply_clause_doesnt_start_with(value, table)
      table.grouping(arel_attribute(table).does_not_match("#{value}%"))
    end

    def apply_clause_doesnt_end_with(value, table)
      table.grouping(arel_attribute(table).does_not_match("%#{value}"))
    end
  end
end
