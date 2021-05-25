module Hammerstone::Refine::Conditions
  class NumericCondition < Condition
    include ActiveModel::Validations
    include HasClauses

    validates :value1, numericality: true, allow_nil: true
    validates :value2, numericality: true, allow_nil: true

    with_options if: :floats_not_allowed? do
      validates :value1, numericality: {only_integer: true}, allow_nil: true
      validates :value2, numericality: {only_integer: true}, allow_nil: true
    end

    attr_reader :value1, :value2

    CLAUSE_EQUALS = Clauses::EQUALS
    CLAUSE_DOESNT_EQUAL = Clauses::DOESNT_EQUAL

    CLAUSE_LESS_THAN_OR_EQUAL = Clauses::LESS_THAN_OR_EQUAL
    CLAUSE_LESS_THAN = Clauses::LESS_THAN
    CLAUSE_GREATER_THAN = Clauses::GREATER_THAN
    CLAUSE_GREATER_THAN_OR_EQUAL = Clauses::GREATER_THAN_OR_EQUAL

    CLAUSE_BETWEEN = Clauses::BETWEEN
    CLAUSE_NOT_BETWEEN = Clauses::NOT_BETWEEN

    CLAUSE_SET = Clauses::SET
    CLAUSE_NOT_SET = Clauses::NOT_SET

    def boot
      @floats = false
    end

    def set_input_parameters(input)
      @value1 = input[:value1]
      @value2 = input[:value2]
    end

    def component
      "numeric-condition"
    end

    def clauses
      [
        Clause.new(CLAUSE_EQUALS, "Is Equal To").requires_inputs(["value1"]),

        Clause.new(CLAUSE_DOESNT_EQUAL, "Is Not Equal To").requires_inputs(["value1"]),

        Clause.new(CLAUSE_GREATER_THAN, "Is Greater Than").requires_inputs(["value1"]),

        Clause.new(CLAUSE_GREATER_THAN_OR_EQUAL, "Is Greater Than Or Equal To").requires_inputs(["value1"]),

        Clause.new(CLAUSE_LESS_THAN, "Is Less Than").requires_inputs(["value1"]),

        Clause.new(CLAUSE_LESS_THAN_OR_EQUAL, "Is Less Than Or Equal To").requires_inputs(["value1"]),

        Clause.new(CLAUSE_BETWEEN, "Is Between").requires_inputs(["value1", "value2"]),

        Clause.new(CLAUSE_NOT_BETWEEN, "Is Not Between").requires_inputs(["value1", "value2"]),

        Clause.new(CLAUSE_SET, "Is Set"),

        Clause.new(CLAUSE_NOT_SET, "Is Not Set"),
      ]
    end

    def allow_floats
      @floats = true
      self
    end

    def floats_not_allowed?
      !@floats
    end

    # Refactor to remove input here
    def apply_condition(input, table)
      # TODO check for custom clause

      case clause
      when CLAUSE_EQUALS
        apply_clause_equals(table, value1)

      when CLAUSE_DOESNT_EQUAL
        apply_clause_doesnt_equal(table, value1)

      when CLAUSE_GREATER_THAN
        apply_clause_greater_than(table, value1)

      when CLAUSE_GREATER_THAN_OR_EQUAL
        apply_clause_greater_than_or_equal(table, value1)

      when CLAUSE_LESS_THAN
        apply_clause_less_than(table, value1)

      when CLAUSE_LESS_THAN_OR_EQUAL
        apply_clause_less_than_or_equal(table, value1)

      when CLAUSE_BETWEEN
        apply_clause_between(table, value1, value2)

      when CLAUSE_NOT_BETWEEN
        apply_clause_not_between(table, value1, value2)

      when CLAUSE_SET
        apply_clause_set(table)

      when CLAUSE_NOT_SET
        apply_clause_not_set(table)
      end
    end

    def apply_clause_equals(table, value)
      table.grouping(table[:"#{attribute}"].eq(value))
    end

    def apply_clause_doesnt_equal(table, value)
      table.grouping(table[:"#{attribute}"].not_eq(value).or(table[:"#{attribute}"].eq(nil)))
    end

    def apply_clause_greater_than(table, value)
      table.grouping(table[:"#{attribute}"].gt(value))
    end

    def apply_clause_greater_than_or_equal(table, value)
      table.grouping(table[:"#{attribute}"].gteq(value))
    end

    def apply_clause_less_than(table, value)
      table.grouping(table[:"#{attribute}"].lt(value))
    end

    def apply_clause_less_than_or_equal(table, value)
      table.grouping(table[:"#{attribute}"].lteq(value))
    end

    def apply_clause_between(table, value1, value2)
      if is_refinement
        Arel.star.count.between(value1..value2)
      else
        table.grouping(table[:"#{attribute}"].between(value1..value2))
      end
    end

    def apply_clause_not_between(table, value1, value2)
      if is_refinement
        Arel.star.count.not_between(value1..value2)
      else
        table.grouping(table[:"#{attribute}"].not_between(value1..value2))
      end
    end

    def apply_clause_set(table)
      table.grouping(table[:"#{attribute}"].not_eq(nil))
    end

    def apply_clause_not_set(table)
      table.grouping(table[:"#{attribute}"].eq(nil))
    end
  end
end
