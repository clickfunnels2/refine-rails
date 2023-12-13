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
      attribute = arel_attribute(table)

      case clause
      when CLAUSE_SET     then attribute.not_eq(nil)
      when CLAUSE_NOT_SET then attribute.eq(nil)
      when CLAUSE_TRUE    then apply_boolean_with_nulls attribute, value: true
      when CLAUSE_FALSE   then apply_boolean_with_nulls attribute, value: false
      end.then { table.grouping _1 if _1 }
    end

    def apply_boolean_with_nulls(attribute, value:)
      attribute.eq(value).then do |node|
        @nulls_are == value ? node.or(attribute.eq(nil)) : node
      end
    end
  end
end
