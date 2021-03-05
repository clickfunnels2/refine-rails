module Hammerstone::Refine::Conditions
  class BooleanCondition < Condition
    include HasClauses

    CLAUSE_TRUE = Clauses::TRUE
    CLAUSE_FALSE = Clauses::FALSE
    CLAUSE_SET = Clauses::SET #non null
    CLAUSE_NOT_SET = Clauses::NOT_SET #null

    def component
      'boolean-condition'
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
        Clause.new(CLAUSE_TRUE, 'Is True'),
        Clause.new(CLAUSE_FALSE, 'Is False'),
        Clause.new(CLAUSE_SET, 'Is Not Set'),
        Clause.new(CLAUSE_NOT_SET, 'Is Not Set'),
      ]
    end

    def apply_condition(relation, input)

      clause = input[:clause]

      case clause
      when CLAUSE_SET
        apply_clause_set(relation)

      when CLAUSE_NOT_SET
        apply_clause_not_set(relation)

      when CLAUSE_TRUE
        apply_clause_true(relation)

      when CLAUSE_FALSE
        apply_clause_false(relation)
      end

      #Apply a custom clause
    end

    def apply_clause_set(relation)
      relation.where.not("#{attribute}": nil)
    end

    def apply_clause_not_set(relation)
      relation.where("#{attribute}": nil)
    end

    def apply_clause_true(relation)
      apply_clause_bool(relation, true)
    end

    def apply_clause_bool(relation, bool)
      if @nulls_are ==  bool
        relation.where("#{attribute}": bool).or(relation.where("#{attribute}": nil))
      else
        relation.where("#{attribute}": bool)
      end
    end

    def apply_clause_false(relation)
      apply_clause_bool(relation, false)
    end

  end
end