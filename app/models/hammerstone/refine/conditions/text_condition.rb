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
      'text-condition'
    end

    def clauses
      [
        Clause.new(CLAUSE_EQUALS, 'Equals')
            .requires_inputs('value'),

        Clause.new(CLAUSE_DOESNT_EQUAL, 'Does Not Equal')
            .requires_inputs('value'),

        Clause.new(CLAUSE_STARTS_WITH, 'Starts With')
            .requires_inputs('value'),

        Clause.new(CLAUSE_ENDS_WITH, 'Ends With')
            .requires_inputs('value'),

        Clause.new(CLAUSE_DOESNT_START_WITH, 'Does Not Start With')
            .requires_inputs('value'),

        Clause.new(CLAUSE_DOESNT_END_WITH, 'Does Not End With')
            .requires_inputs('value'),

        Clause.new(CLAUSE_CONTAINS, 'Contains')
            .requires_inputs('value'),

        Clause.new(CLAUSE_DOESNT_CONTAIN, 'Does Not Contain')
            .requires_inputs('value'),

        Clause.new(CLAUSE_SET, 'Is Set'),

        Clause.new(CLAUSE_NOT_SET, 'Is Not Set')
      ]
    end

    def apply_condition(relation, input)
      clause = input[:clause]
      value = input[:value]

      case clause
      when CLAUSE_EQUALS
        apply_clause_equals(relation, value)

      when CLAUSE_DOESNT_EQUAL
        apply_clause_doesnt_equal(relation, value)

      when CLAUSE_STARTS_WITH
        apply_clause_starts_with(relation, value)

      when CLAUSE_ENDS_WITH
        apply_clause_ends_with(relation, value)

      when CLAUSE_DOESNT_START_WITH
        apply_clause_doesnt_start_with(relation, value)

      when CLAUSE_DOESNT_END_WITH
        apply_clause_doesnt_end_with(relation, value)

      when CLAUSE_CONTAINS
        apply_clause_contains(relation, value)

      when CLAUSE_DOESNT_CONTAIN
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

    def apply_clause_doesnt_equal(relation, value)
      relation.where.not("#{attribute}": value).or(relation.where("#{attribute}": nil))
    end

    def apply_clause_starts_with(relation, value)
      relation.where("#{attribute} LIKE ?", "#{value}%")
    end

    def apply_clause_ends_with(relation, value)
      relation.where("#{attribute} LIKE ?", "%#{value}")
    end

    def apply_clause_contains(relation, value)
      relation.where("#{attribute} LIKE ?", "%#{value}%")
    end

    def apply_clause_doesnt_contain(relation, value)
      relation.where("#{attribute} NOT LIKE ?", "%#{value}%").or(relation.where("#{attribute}": nil))
    end

    def apply_clause_set(relation, value)
      relation.where.not("#{attribute}": [nil, ""])
    end

    def apply_clause_not_set(relation, value)
      relation.where(text_test: [nil, ""])
    end

    def apply_clause_doesnt_start_with(relation, value)
      relation.where("#{attribute} NOT LIKE ?", "#{value}%")
    end

    def apply_clause_doesnt_end_with(relation, value)
      relation.where("#{attribute} NOT LIKE ?","%#{value}" )
    end
  end
end