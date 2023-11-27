module Refine::Conditions
  class NumericCondition < Condition
    include ActiveModel::Validations
    include HasClauses

    cattr_accessor :default_clause_display_map, default: {}, instance_accessor: false

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

    I18N_PREFIX = "refine.refine_blueprints.numeric_condition."

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

    def human_readable(input)
      current_clause = get_clause_by_id(input[:clause])
      case input[:clause]
      when *[CLAUSE_EQUALS, CLAUSE_DOESNT_EQUAL, CLAUSE_GREATER_THAN, CLAUSE_GREATER_THAN_OR_EQUAL, CLAUSE_LESS_THAN, CLAUSE_LESS_THAN_OR_EQUAL]
        "#{display} #{current_clause.display} #{input[:value1]}"
      when *[CLAUSE_BETWEEN, CLAUSE_NOT_BETWEEN]
        "#{display} #{current_clause.display} #{input[:value1]} #{I18n.t("#{I18N_PREFIX}and")} #{input[:value2]}"
      when *[CLAUSE_SET, CLAUSE_NOT_SET]
        "#{display} #{current_clause.display}"
      else
        raise "#{input[:clause]} #{I18n.t("#{I18N_PREFIX}not_supported")}"
      end
    end

    def human_readable_value(input)
      current_clause = get_clause_by_id(input[:clause])
      case input[:clause]
      when *[CLAUSE_EQUALS, CLAUSE_DOESNT_EQUAL, CLAUSE_GREATER_THAN, CLAUSE_GREATER_THAN_OR_EQUAL, CLAUSE_LESS_THAN, CLAUSE_LESS_THAN_OR_EQUAL]
        input[:value1]
      when *[CLAUSE_BETWEEN, CLAUSE_NOT_BETWEEN]
        "#{input[:value1]} #{I18n.t("#{I18N_PREFIX}and")} #{input[:value2]}"
      when *[CLAUSE_SET, CLAUSE_NOT_SET]
        ""
      else
        raise "#{input[:clause]} #{I18n.t("#{I18N_PREFIX}not_supported")}"
      end
    end



    def clauses
      [
        Clause.new(CLAUSE_EQUALS, I18n.t("#{I18N_PREFIX}is")).requires_inputs(["value1"]),

        Clause.new(CLAUSE_DOESNT_EQUAL, I18n.t("#{I18N_PREFIX}is_not")).requires_inputs(["value1"]),

        Clause.new(CLAUSE_GREATER_THAN, I18n.t("#{I18N_PREFIX}is_gt")).requires_inputs(["value1"]),

        Clause.new(CLAUSE_GREATER_THAN_OR_EQUAL, I18n.t("#{I18N_PREFIX}is_gtteq")).requires_inputs(["value1"]),

        Clause.new(CLAUSE_LESS_THAN, I18n.t("#{I18N_PREFIX}is_lt")).requires_inputs(["value1"]),

        Clause.new(CLAUSE_LESS_THAN_OR_EQUAL, I18n.t("#{I18N_PREFIX}is_lteq")).requires_inputs(["value1"]),

        Clause.new(CLAUSE_BETWEEN, I18n.t("#{I18N_PREFIX}is_between")).requires_inputs(["value1", "value2"]),

        Clause.new(CLAUSE_NOT_BETWEEN, I18n.t("#{I18N_PREFIX}is_not_between")).requires_inputs(["value1", "value2"]),

        Clause.new(CLAUSE_SET, I18n.t("#{I18N_PREFIX}is_set")),

        Clause.new(CLAUSE_NOT_SET, I18n.t("#{I18N_PREFIX}is_not_set")),
      ]
    end

    def allow_floats
      @floats = true
      self
    end

    def floats_not_allowed?
      !@floats
    end

    def input_could_include_zero?(input)
      clause = input[:clause]
      value1 = input[:value1].to_i
      value2 = input[:value2].to_i
      case clause
      when CLAUSE_EQUALS
        return value1 == 0

      when CLAUSE_DOESNT_EQUAL
        return value1 != 0

      when CLAUSE_LESS_THAN_OR_EQUAL
        return value1 >= 0

      when CLAUSE_LESS_THAN
        return value1 > 0

      when CLAUSE_GREATER_THAN
        return value1 < 0

      when CLAUSE_GREATER_THAN_OR_EQUAL
        return value1 <= 0

      when CLAUSE_BETWEEN
        return value1 <= 0 && value2 >= 0

      when CLAUSE_NOT_BETWEEN
        return (value1 > 0 && value2 > 0) || (value1 < 0 && value2 < 0)

      when CLAUSE_SET
        return false

      when CLAUSE_NOT_SET
        return false
      end
    end

    # TODO Refactor to remove input here
    def apply_condition(input, table, _inverse_clause)
      # TODO check for custom clause
      attribute = arel_attribute(table)

      case clause
      when CLAUSE_EQUALS                then attribute.eq(value1)
      when CLAUSE_DOESNT_EQUAL          then attribute.not_eq(value1).or(attribute.eq(nil))
      when CLAUSE_GREATER_THAN          then attribute.gt(value1)
      when CLAUSE_GREATER_THAN_OR_EQUAL then attribute.gteq(value1)
      when CLAUSE_LESS_THAN             then attribute.lt(value1)
      when CLAUSE_LESS_THAN_OR_EQUAL    then attribute.lteq(value1)
      when CLAUSE_BETWEEN               then attribute.between(value1..value2)
      when CLAUSE_NOT_BETWEEN           then attribute.not_between(value1..value2)
      when CLAUSE_SET                   then attribute.not_eq(nil)
      when CLAUSE_NOT_SET               then attribute.eq(nil)
      end.then { table.grouping _1 if _1 }
    end
  end
end
