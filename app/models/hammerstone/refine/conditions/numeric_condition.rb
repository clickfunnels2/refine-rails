module Hammerstone::Refine::Conditions
  class NumericCondition < Condition

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
      # TODO "Add some nullable rules here!"
    end

    def clauses
      [
        Clause.new(CLAUSE_EQUALS, 'Is Equal To').requiresInputs('value1'),

        Clause.new(CLAUSE_DOESNT_EQUAL, 'Is Not Equal To').requiresInputs('value1'),

        Clause.new(CLAUSE_GREATER_THAN, 'Is Greater Than').requiresInputs('value1'),

        Clause.new(CLAUSE_GREATER_THAN_OR_EQUAL, 'Is Greater Than Or Equal To').requiresInputs('value1'),

        Clause.new(CLAUSE_LESS_THAN, 'Is Less Than').requiresInputs('value1'),

        Clause.new(CLAUSE_LESS_THAN_OR_EQUAL, 'Is Less Than Or Equal To').requiresInputs('value1'),

        Clause.new(CLAUSE_BETWEEN, 'Is Between').requiresInputs(['value1', 'value2']),

        Clause.new(CLAUSE_NOT_BETWEEN, 'Is Not Between').requiresInputs(['value1', 'value2']),

        Clause.new(CLAUSE_SET, 'Is Set'),

        Clause.new(CLAUSE_NOT_SET, 'Is Not Set'),
      ]
    end

    def apply_condition(relation, input)
      clause = input[:clause]
      value1 = input[:value1]
      value2 = input[:value2]
      #TODO check for custom clause

      case clause
      when CLAUSE_EQUALS
        apply_clause_equals(relation, value1)

      when CLAUSE_DOESNT_EQUAL
        apply_clause_doesnt_equal(relation, value)

      when CLAUSE_GREATER_THAN
        apply_clause_greater_than(relation, value1)

      when CLAUSE_GREATER_THAN_OR_EQUAL
        apply_clause_greater_than_or_equal(relation, value1)

      when CLAUSE_LESS_THAN
        apply_clause_less_than(relation, value1)

      when CLAUSE_LESS_THAN_OR_EQUAL
        apply_clause_less_than_or_equal(relation, value1)

      when CLAUSE_BETWEEN
        apply_clause_contains(relation, value)

      when CLAUSE_NOT_BETWEEN
        apply_clause_doesnt_contain(relation, value)

      when CLAUSE_SET
        apply_clause_set(relation, value)

      when CLAUSE_NOT_SET
        apply_clause_not_set(relation, value)
      end
    end

    def apply_clause_equals(relation, value)
      relation.where("#{attribute}": value)
    end

    def apply_clause_greater_than(relation, value)
      relation.where("#{attribute} > ?", value)
    end

    def apply_clause_greater_than_or_equal(relation, value)
      relation.where("#{attribute} >= ?", value)
    end

    def apply_clause_less_than(relation, value)
      relation.where("#{attribute} < ?", value)
    end

    def apply_clause_less_than_or_equal(relation, value)
      relation.where("#{attribute} <= ?", value)
    end

    #How it should be serializing, validating . to array method what is exposed to the world
    #apply clauses applying user input to a query.

  end
end