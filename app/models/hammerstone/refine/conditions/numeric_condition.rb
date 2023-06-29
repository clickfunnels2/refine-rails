module Hammerstone::Refine::Conditions
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

    I18N_PREFIX = "hammerstone.refine_blueprints.numeric_condition."

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

    # TODO Refactor to remove input here
    def apply_condition(input, table, _inverse_clause)
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

    def apply_clause_equals(table, value)
      table.grouping(arel_attribute(table).eq(value))
    end

    def apply_clause_doesnt_equal(table, value)
      table.grouping(arel_attribute(table).not_eq(value).or(arel_attribute(table).eq(nil)))
    end

    def apply_clause_greater_than(table, value)
      table.grouping(arel_attribute(table).gt(value))
    end

    def apply_clause_greater_than_or_equal(table, value)
      table.grouping(arel_attribute(table).gteq(value))
    end

    def apply_clause_less_than(table, value)
      table.grouping(arel_attribute(table).lt(value))
    end

    def apply_clause_less_than_or_equal(table, value)
      table.grouping(arel_attribute(table).lteq(value))
    end

    def apply_clause_between(table, value1, value2)
      table.grouping(arel_attribute(table).between(value1..value2))
    end

    def apply_clause_not_between(table, value1, value2)
      table.grouping(arel_attribute(table).not_between(value1..value2))
    end

    def apply_clause_set(table)
      table.grouping(arel_attribute(table).not_eq(nil))
    end

    def apply_clause_not_set(table)
      table.grouping(arel_attribute(table).eq(nil))
    end
  end
end
