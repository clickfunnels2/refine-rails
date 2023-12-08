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
      when Clauses::EQUALS, Clauses::DOESNT_EQUAL, Clauses::GREATER_THAN, Clauses::GREATER_THAN_OR_EQUAL, Clauses::LESS_THAN, Clauses::LESS_THAN_OR_EQUAL
        "#{display} #{current_clause.display} #{input[:value1]}"
      when Clauses::BETWEEN, Clauses::NOT_BETWEEN
        "#{display} #{current_clause.display} #{input[:value1]} #{I18n.t("#{I18N_PREFIX}and")} #{input[:value2]}"
      when Clauses::SET, Clauses::NOT_SET
        "#{display} #{current_clause.display}"
      else
        raise "#{input[:clause]} #{I18n.t("#{I18N_PREFIX}not_supported")}"
      end
    end

    def human_readable_value(input)
      current_clause = get_clause_by_id(input[:clause])
      case input[:clause]
      when Clauses::EQUALS, Clauses::DOESNT_EQUAL, Clauses::GREATER_THAN, Clauses::GREATER_THAN_OR_EQUAL, Clauses::LESS_THAN, Clauses::LESS_THAN_OR_EQUAL
        input[:value1]
      when Clauses::BETWEEN, Clauses::NOT_BETWEEN
        "#{input[:value1]} #{I18n.t("#{I18N_PREFIX}and")} #{input[:value2]}"
      when Clauses::SET, Clauses::NOT_SET
        ""
      else
        raise "#{input[:clause]} #{I18n.t("#{I18N_PREFIX}not_supported")}"
      end
    end



    def clauses
      [
        Clause.new(Clauses::EQUALS, I18n.t("#{I18N_PREFIX}is")).requires_inputs(["value1"]),

        Clause.new(Clauses::DOESNT_EQUAL, I18n.t("#{I18N_PREFIX}is_not")).requires_inputs(["value1"]),

        Clause.new(Clauses::GREATER_THAN, I18n.t("#{I18N_PREFIX}is_gt")).requires_inputs(["value1"]),

        Clause.new(Clauses::GREATER_THAN_OR_EQUAL, I18n.t("#{I18N_PREFIX}is_gtteq")).requires_inputs(["value1"]),

        Clause.new(Clauses::LESS_THAN, I18n.t("#{I18N_PREFIX}is_lt")).requires_inputs(["value1"]),

        Clause.new(Clauses::LESS_THAN_OR_EQUAL, I18n.t("#{I18N_PREFIX}is_lteq")).requires_inputs(["value1"]),

        Clause.new(Clauses::BETWEEN, I18n.t("#{I18N_PREFIX}is_between")).requires_inputs(["value1", "value2"]),

        Clause.new(Clauses::NOT_BETWEEN, I18n.t("#{I18N_PREFIX}is_not_between")).requires_inputs(["value1", "value2"]),

        Clause.new(Clauses::SET, I18n.t("#{I18N_PREFIX}is_set")),

        Clause.new(Clauses::NOT_SET, I18n.t("#{I18N_PREFIX}is_not_set")),
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
      when Clauses::EQUALS
        apply_clause_equals(table, value1)

      when Clauses::DOESNT_EQUAL
        apply_clause_doesnt_equal(table, value1)

      when Clauses::GREATER_THAN
        apply_clause_greater_than(table, value1)

      when Clauses::GREATER_THAN_OR_EQUAL
        apply_clause_greater_than_or_equal(table, value1)

      when Clauses::LESS_THAN
        apply_clause_less_than(table, value1)

      when Clauses::LESS_THAN_OR_EQUAL
        apply_clause_less_than_or_equal(table, value1)

      when Clauses::BETWEEN
        apply_clause_between(table, value1, value2)

      when Clauses::NOT_BETWEEN
        apply_clause_not_between(table, value1, value2)

      when Clauses::SET
        apply_clause_set(table)

      when Clauses::NOT_SET
        apply_clause_not_set(table)
      end
    end

    def input_could_include_zero?(input)
      clause = input[:clause]
      value1 = input[:value1].to_i
      value2 = input[:value2].to_i
      case clause
      when Clauses::EQUALS
        return value1 == 0

      when Clauses::DOESNT_EQUAL
        return value1 != 0

      when Clauses::LESS_THAN_OR_EQUAL
        return value1 >= 0

      when Clauses::LESS_THAN
        return value1 > 0

      when Clauses::GREATER_THAN
        return value1 < 0

      when Clauses::GREATER_THAN_OR_EQUAL
        return value1 <= 0

      when Clauses::BETWEEN
        return value1 <= 0 && value2 >= 0

      when Clauses::NOT_BETWEEN
        return (value1 > 0 && value2 > 0) || (value1 < 0 && value2 < 0)

      when Clauses::SET
        return false

      when Clauses::NOT_SET
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
