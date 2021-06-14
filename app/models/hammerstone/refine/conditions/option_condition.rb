module Hammerstone::Refine::Conditions
  class OptionCondition < Condition
    include HasClauses
    include UsesAttributes
    include ActiveModel::Validations

    validate :select_is_array
    validate :option_in_approved_list?

    attr_reader :selected, :nil_option_id, :options

    CLAUSE_EQUALS = Clauses::EQUALS
    CLAUSE_DOESNT_EQUAL = Clauses::DOESNT_EQUAL

    CLAUSE_IN = Clauses::IN
    CLAUSE_NOT_IN = Clauses::NOT_IN

    CLAUSE_SET = Clauses::SET
    CLAUSE_NOT_SET = Clauses::NOT_SET

    def component
      "option-condition"
    end

    def boot
      @nil_option_id = nil
      @options = nil
      @validate_selections = true
      with_meta({options: get_options})
      add_ensurance(ensure_options)
    end

    def set_input_parameters(input)
      @selected = input[:selected]
    end

    def select_is_array
      errors.add(:base, "Select must be an array") unless selected.is_a?(Array)
    end

    def option_in_approved_list?
      selected.each do |select|
        unless get_options.call.map { |option| option[:id] }.include? select
          errors.add(:base, "Selected #{select} is not configured in options list")
        end
      end
    end

    def get_options
      proc do
        @options = call_proc_if_callable(options)
      end
    end

    def ensure_options
      proc do
        developer_options = get_options.call
        # Options must be sent in as an array
        if !developer_options.is_a? Array
          raise "No options could be determined"
        end
        # Each option must be a hash of values that includes :id and :display
        developer_options.each do |option|
          if (!option.is_a? Hash) || option.keys.exclude?(:id) || option.keys.exclude?(:display)
            raise Hammerstone::Refine::Conditions::Errors::OptionError.new("An option must have an id and a display attribute.")
          end
        end
        ensure_no_duplicates(developer_options)
      end
    end

    def ensure_no_duplicates(developer_options)
      id_array = developer_options.map { |option| option[:id] }
      duplicates = id_array.select { |id| id_array.count(id) > 1 }.uniq
      if duplicates.present?
        raise Hammerstone::Refine::Conditions::Errors::OptionError.new("Options must have unique IDs. Duplicate #{duplicates} found.")
      end
    end

    def clauses
      [
        Clause.new(CLAUSE_EQUALS, "Is")
          .requires_inputs(["selected"]),

        Clause.new(CLAUSE_DOESNT_EQUAL, "Is Not")
          .requires_inputs(["selected"]),

        Clause.new(CLAUSE_IN, "Is One Of")
          .requires_inputs(["selected"]),

        Clause.new(CLAUSE_NOT_IN, "Is Not One Of")
          .requires_inputs(["selected"]),

        Clause.new(CLAUSE_SET, "Is Set"),

        Clause.new(CLAUSE_NOT_SET, "Is Not Set")
      ]
    end

    def apply_condition(input, table)
      value = selected

      case clause
      when CLAUSE_SET
        apply_clause_set(table)

      when CLAUSE_NOT_SET
        apply_clause_not_set(table)

      when CLAUSE_EQUALS
        apply_clause_equals(value, table)

      when CLAUSE_DOESNT_EQUAL
        apply_clause_doesnt_equal(value, table)

      when CLAUSE_IN
        apply_clause_in(value, table)

      when CLAUSE_NOT_IN
        apply_clause_not_in(value, table)
      end
    end

    def with_options(developer_configured_options)
      @options = developer_configured_options
      self
    end

    def with_nil_option(id)
      @nil_option_id = id
      self
    end

    def nil_option_selected?(value)
      # Return false if no nil option id
      return false unless nil_option_id
      value.include? nil_option_id
    end

    def values_for_application(ids, single = false)
      # Get developer configured options with nil_option_id removed and select only elements from requested ids
      # Extract values from either _value key or id key. _value can be a callable
      values = get_options.call.delete_if { |el| el[:id] == nil_option_id }
        .select { |value| ids.include? value[:id] }
        .map! { |value| (value.has_key? :_value) ? call_proc_if_callable(value[:_value]) : value[:id] }
      single ? values[0] : values
    end

    def apply_nil_query(value, table)
      table.grouping(table[:"#{attribute}"].eq(nil))
    end

    def apply_not_nil_query(value, table)
      table.grouping(table[:"#{attribute}"].not_eq(nil))
    end

    def apply_equals(value, table)
      table.grouping(table[:"#{attribute}"].eq(value))
    end

    def apply_clause_in(value, table)
      normalized_values = values_for_application(value)

      if nil_option_selected?(value)
        table.grouping(table[:"#{attribute}"].in(normalized_values).or(table[:"#{attribute}"].eq(nil)))
      else
        table.grouping(table[:"#{attribute}"].in(normalized_values))
      end
    end

    def apply_clause_not_in(value, table)
      normalized_values = values_for_application(value)
      # Must check for only nil option selected here
      if nil_option_selected?(value) && value.one?
        table.grouping(table[:"#{attribute}"].not_eq(nil))
      elsif nil_option_selected?(value)
        table.grouping(table[:"#{attribute}"].not_in(normalized_values).or(table[:"#{attribute}"].not_eq(nil)))
      else
        table.grouping(table[:"#{attribute}"].not_in(normalized_values).or(table[:"#{attribute}"].eq(nil)))
      end
    end

    def apply_clause_equals(value, table)
      if nil_option_selected?(value)
        apply_nil_query(value, table)
      else
        apply_equals(values_for_application(value, true), table)
      end
    end

    def apply_clause_doesnt_equal(value, table)
      if nil_option_selected?(value)
        apply_not_nil_query(value, table)
      else
        apply_not_equals(values_for_application(value, true), table)
      end
    end

    def apply_not_equals(value, table)
      table.grouping(table[:"#{attribute}"].not_eq(value).or(table[:"#{attribute}"].eq(nil)))
    end

    def apply_clause_set(value, table)
      table.grouping(table[:"#{attribute}"].not_eq_any([nil, ""]))
    end

    def apply_clause_not_set(value, table)
      table.grouping(table[:"#{attribute}"].eq_any([nil, ""]))
    end
  end
end