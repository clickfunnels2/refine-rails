module Refine::Conditions
  class TextCondition < Condition
    include HasClauses

    CLAUSE_EQUALS = Clauses::EQUALS
    CLAUSE_DOESNT_EQUAL = Clauses::DOESNT_EQUAL

    CLAUSE_STARTS_WITH = Clauses::STARTS_WITH
    CLAUSE_ENDS_WITH = Clauses::ENDS_WITH
    CLAUSE_DOESNT_START_WITH = Clauses::DOESNT_START_WITH
    CLAUSE_DOESNT_END_WITH = Clauses::DOESNT_END_WITH

    CLAUSE_CONTAINS = Clauses::CONTAINS
    CLAUSE_DOESNT_CONTAIN = Clauses::DOESNT_CONTAIN

    CLAUSE_SET = Clauses::SET

    CLAUSE_NOT_SET = Clauses::NOT_SET

    I18N_PREFIX = "refine.refine_blueprints.text_condition."

    def component
      "text-condition"
    end

    def human_readable(input)
      current_clause = get_clause_by_id(input[:clause])
      if input[:clause].in? [CLAUSE_SET, CLAUSE_NOT_SET]
        "#{display} #{current_clause.display}"
      else
        "#{display} #{current_clause.display} #{input[:value]}"
      end
    end

    def human_readable_value(input)
      current_clause = get_clause_by_id(input[:clause])
      if input[:clause].in? [CLAUSE_SET, CLAUSE_NOT_SET]
        ""
      else
        input[:value]
      end
    end

    def clauses
      [
        Clause.new(CLAUSE_EQUALS, I18n.t("#{I18N_PREFIX}is"))
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_DOESNT_EQUAL, I18n.t("#{I18N_PREFIX}is_not"))
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_STARTS_WITH, I18n.t("#{I18N_PREFIX}starts_with"))
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_ENDS_WITH, I18n.t("#{I18N_PREFIX}ends_with"))
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_DOESNT_START_WITH, I18n.t("#{I18N_PREFIX}does_not_start_with"))
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_DOESNT_END_WITH, I18n.t("#{I18N_PREFIX}does_not_end_with"))
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_CONTAINS, I18n.t("#{I18N_PREFIX}contains"))
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_DOESNT_CONTAIN, I18n.t("#{I18N_PREFIX}does_not_contain"))
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_SET, I18n.t("#{I18N_PREFIX}is_set")),

        Clause.new(CLAUSE_NOT_SET, I18n.t("#{I18N_PREFIX}is_not_set"))
      ]
    end

    def apply_condition(input, table, _inverse_clause)
      attribute, value = arel_attribute(table), input[:value]

      case clause
      when CLAUSE_EQUALS            then apply_clause_equals(attribute, value)
      when CLAUSE_DOESNT_EQUAL      then apply_clause_doesnt_equal(attribute, value)
      when CLAUSE_STARTS_WITH       then apply_clause_starts_with(attribute, value)
      when CLAUSE_ENDS_WITH         then apply_clause_ends_with(attribute, value)
      when CLAUSE_DOESNT_START_WITH then apply_clause_doesnt_start_with(attribute, value)
      when CLAUSE_DOESNT_END_WITH   then apply_clause_doesnt_end_with(attribute, value)
      when CLAUSE_CONTAINS          then apply_clause_contains(attribute, value)
      when CLAUSE_DOESNT_CONTAIN    then apply_clause_doesnt_contain(attribute, value)
      when CLAUSE_SET               then apply_clause_set(attribute, value)
      when CLAUSE_NOT_SET           then apply_clause_not_set(attribute, value)
      end.then { table.grouping _1 if _1 }
    end

    def apply_clause_equals(attribute, value)
      attribute.eq(value)
    end

    def apply_clause_doesnt_equal(attribute, value)
      attribute.not_eq(value).or(attribute.eq(nil))
    end

    def apply_clause_starts_with(attribute, value)
      attribute.matches("#{value}%")
    end

    def apply_clause_ends_with(attribute, value)
      attribute.matches("%#{value}")
    end

    def apply_clause_contains(attribute, value)
      attribute.matches("%#{value}%")
    end

    def apply_clause_doesnt_contain(attribute, value)
      attribute.does_not_match("%#{value}%").or(attribute.eq(nil))
    end

    def apply_clause_set(attribute, _)
      attribute.not_eq_all([nil, ""])
    end

    def apply_clause_not_set(attribute, _)
      attribute.eq_any([nil, ""])
    end

    def apply_clause_doesnt_start_with(attribute, value)
      attribute.does_not_match("#{value}%")
    end

    def apply_clause_doesnt_end_with(attribute, value)
      attribute.does_not_match("%#{value}")
    end
  end
end
