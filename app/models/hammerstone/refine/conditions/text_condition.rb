module Hammerstone::Refine::Conditions
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

    def clauses
      [
        Clause.new(CLAUSE_EQUALS, "is")
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_DOESNT_EQUAL, "is not")
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_STARTS_WITH, "starts with")
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_ENDS_WITH, "ends with")
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_DOESNT_START_WITH, "does not start with")
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_DOESNT_END_WITH, "does not end with")
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_CONTAINS, "contains")
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_DOESNT_CONTAIN, "does not contain")
          .requires_inputs(["value"]),

        Clause.new(CLAUSE_SET, "is set"),

        Clause.new(CLAUSE_NOT_SET, "is not set")
      ]
    end

    def apply_condition(input, table, _inverse_clause)
      value = input[:value]

      case clause
      when CLAUSE_EQUALS
        apply_clause_equals(value, table)

      when CLAUSE_DOESNT_EQUAL
        apply_clause_doesnt_equal(value, table)

      when CLAUSE_STARTS_WITH
        apply_clause_starts_with(value, table)

      when CLAUSE_ENDS_WITH
        apply_clause_ends_with(value, table)

      when CLAUSE_DOESNT_START_WITH
        apply_clause_doesnt_start_with(value, table)

      when CLAUSE_DOESNT_END_WITH
        apply_clause_doesnt_end_with(value, table)

      when CLAUSE_CONTAINS
        apply_clause_contains(value, table)

      when CLAUSE_DOESNT_CONTAIN
        apply_clause_doesnt_contain(value, table)

      when CLAUSE_SET
        apply_clause_set(value, table)

      when CLAUSE_NOT_SET
        apply_clause_not_set(value, table)
      end
    end

    def apply_clause_equals(value, table)
      table.grouping(table[:"#{attribute}"].eq(value))
    end

    def apply_clause_doesnt_equal(value, table)
      table.grouping(table[:"#{attribute}"].not_eq(value).or(table[:"#{attribute}"].eq(nil)))
    end

    def apply_clause_starts_with(value, table)
      table.grouping(table[:"#{attribute}"].matches("#{value}%"))
    end

    def apply_clause_ends_with(value, table)
      table.grouping(table[:"#{attribute}"].matches("%#{value}"))
    end

    def apply_clause_contains(value, table)
      table.grouping(table[:"#{attribute}"].matches("%#{value}%"))
    end

    def apply_clause_doesnt_contain(value, table)
      table.grouping(table[:"#{attribute}"].does_not_match("%#{value}%").or(table[:"#{attribute}"].eq(nil)))
    end

    def apply_clause_set(value, table)
      table.grouping(table[:"#{attribute}"].not_eq_any([nil, ""]))
    end

    def apply_clause_not_set(value, table)
      table.grouping(table[:"#{attribute}"].eq_any([nil, ""]))
    end

    def apply_clause_doesnt_start_with(value, table)
      table.grouping(table[:"#{attribute}"].does_not_match("#{value}%"))
    end

    def apply_clause_doesnt_end_with(value, table)
      table.grouping(table[:"#{attribute}"].does_not_match("%#{value}"))
    end
  end
end
