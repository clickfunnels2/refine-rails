module Refine::Conditions
  class TextCondition < Condition
    include HasClauses

    I18N_PREFIX = "refine.refine_blueprints.text_condition."

    def component
      "text-condition"
    end

    def human_readable(input)
      current_clause = get_clause_by_id(input[:clause])
      if input[:clause].in? [Clauses::SET, Clauses::NOT_SET]
        "#{display} #{current_clause.display}"
      else
        "#{display} #{current_clause.display} #{input[:value]}"
      end
    end

    def human_readable_value(input)
      current_clause = get_clause_by_id(input[:clause])
      if input[:clause].in? [Clauses::SET, Clauses::NOT_SET]
        ""
      else
        input[:value]
      end
    end

    def clauses
      [
        Clause.new(Clauses::EQUALS, I18n.t("#{I18N_PREFIX}is"))
          .requires_inputs(["value"]),

        Clause.new(Clauses::DOESNT_EQUAL, I18n.t("#{I18N_PREFIX}is_not"))
          .requires_inputs(["value"]),

        Clause.new(Clauses::STARTS_WITH, I18n.t("#{I18N_PREFIX}starts_with"))
          .requires_inputs(["value"]),

        Clause.new(Clauses::ENDS_WITH, I18n.t("#{I18N_PREFIX}ends_with"))
          .requires_inputs(["value"]),

        Clause.new(Clauses::DOESNT_START_WITH, I18n.t("#{I18N_PREFIX}does_not_start_with"))
          .requires_inputs(["value"]),

        Clause.new(Clauses::DOESNT_END_WITH, I18n.t("#{I18N_PREFIX}does_not_end_with"))
          .requires_inputs(["value"]),

        Clause.new(Clauses::CONTAINS, I18n.t("#{I18N_PREFIX}contains"))
          .requires_inputs(["value"]),

        Clause.new(Clauses::DOESNT_CONTAIN, I18n.t("#{I18N_PREFIX}does_not_contain"))
          .requires_inputs(["value"]),

        Clause.new(Clauses::SET, I18n.t("#{I18N_PREFIX}is_set")),

        Clause.new(Clauses::NOT_SET, I18n.t("#{I18N_PREFIX}is_not_set"))
      ]
    end

    def apply_condition(input, table, _inverse_clause)
      value = input[:value]

      case clause
      when Clauses::EQUALS
        apply_clause_equals(value, table)

      when Clauses::DOESNT_EQUAL
        apply_clause_doesnt_equal(value, table)

      when Clauses::STARTS_WITH
        apply_clause_starts_with(value, table)

      when Clauses::ENDS_WITH
        apply_clause_ends_with(value, table)

      when Clauses::DOESNT_START_WITH
        apply_clause_doesnt_start_with(value, table)

      when Clauses::DOESNT_END_WITH
        apply_clause_doesnt_end_with(value, table)

      when Clauses::CONTAINS
        apply_clause_contains(value, table)

      when Clauses::DOESNT_CONTAIN
        apply_clause_doesnt_contain(value, table)

      when Clauses::SET
        apply_clause_set(value, table)

      when Clauses::NOT_SET
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
