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
      when CLAUSE_EQUALS            then attribute.eq(value)
      when CLAUSE_DOESNT_EQUAL      then attribute.not_eq(value).or(attribute.eq(nil))
      when CLAUSE_STARTS_WITH       then attribute.matches("#{value}%")
      when CLAUSE_DOESNT_START_WITH then attribute.does_not_match("#{value}%")
      when CLAUSE_ENDS_WITH         then attribute.matches("%#{value}")
      when CLAUSE_DOESNT_END_WITH   then attribute.does_not_match("%#{value}")
      when CLAUSE_CONTAINS          then attribute.matches("%#{value}%")
      when CLAUSE_DOESNT_CONTAIN    then attribute.does_not_match("%#{value}%").or(attribute.eq(nil))
      when CLAUSE_SET               then attribute.not_eq_all([nil, ""])
      when CLAUSE_NOT_SET           then attribute.eq_any([nil, ""])
      end.then { table.grouping _1 if _1 }
    end
  end
end
