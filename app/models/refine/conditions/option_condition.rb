module Refine::Conditions
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

    I18N_PREFIX = "refine.refine_blueprints.option_condition."

    def component
      "option-condition"
    end

    def human_readable(input)
      current_clause = get_clause_by_id(input[:clause])
      display_values = input[:selected]&.map {|option_id| get_options.call.find{|option| option[:id] == option_id}[:display]}.to_a
      case input[:clause]
      when *[CLAUSE_EQUALS, CLAUSE_DOESNT_EQUAL]
        "#{display} #{current_clause.display} #{display_values.first}"
      when *[CLAUSE_IN, CLAUSE_NOT_IN]
        if display_values.length >= 3
          display_values = display_values.take(2) + ["..."]
        end
        "#{display} #{current_clause.display}: #{display_values.join(", ")}"
      when *[CLAUSE_SET, CLAUSE_NOT_SET]
        "#{display} #{current_clause.display}"
      else
        raise "#{input[:clause]} #{I18n.t("#{I18N_PREFIX}not_supported")}"
      end
    end

    def human_readable_value(input)
      current_clause = get_clause_by_id(input[:clause])
      display_values = input[:selected]&.map {|option_id| get_options.call.find{|option| option[:id] == option_id}[:display]}.to_a
      case input[:clause]
      when *[CLAUSE_EQUALS, CLAUSE_DOESNT_EQUAL]
        display_values.first
      when *[CLAUSE_IN, CLAUSE_NOT_IN]
        if display_values.length >= 3
          display_values = display_values.take(2) + ["..."]
        end
        display_values.join(", ")
      when *[CLAUSE_SET, CLAUSE_NOT_SET]
        ""
      else
        raise "#{input[:clause]} #{I18n.t("#{I18N_PREFIX}not_supported")}"
      end
    end

    def boot
      @nil_option_id = nil
      @options = nil
      # TODO @validate_selections = true
      with_meta({options: get_options})
      add_ensurance(ensure_options)
    end

    def set_input_parameters(input)
      @selected = input[:selected]
    end

    def select_is_array
      errors.add(:base, I18n.t("#{I18N_PREFIX}must_be_array")) unless selected.is_a?(Array)
    end

    def option_in_approved_list?
      # TODO allow this to accept integers as well as strings. Right now must be a string.
      return if selected.nil?
      selected.each do |select|
        select.join if select.is_a? Array
        unless get_options.call.map { |option| option[:id] }.include? select
          errors.add(:base, I18n.t("#{I18N_PREFIX}not_approved", select: select))
        end
      end
    end

    def get_options
      proc do
        @options = Refine::Rails.configuration.option_condition_ordering.call(
          call_proc_if_callable(options)
        )
      end
    end

    def ensure_options
      proc do
        developer_options = get_options.call
        # Options must be sent in as an array
        if !developer_options.is_a? Array
          raise I18n.t("#{I18N_PREFIX}not_determined")
        end
        # Each option must be a hash of values that includes :id and :display
        developer_options.each do |option|
          if (!option.is_a? Hash) || option.keys.exclude?(:id) || option.keys.exclude?(:display)
            raise Refine::Conditions::Errors::OptionError.new(I18n.t("#{I18N_PREFIX}must_have_id_and_display"))
          end
        end
        ensure_no_duplicates(developer_options)
      end
    end

    def ensure_no_duplicates(developer_options)
      id_array = developer_options.map { |option| option[:id] }
      duplicates = id_array.select { |id| id_array.count(id) > 1 }.uniq
      if duplicates.present?
        raise Refine::Conditions::Errors::OptionError.new(I18n.t("#{I18N_PREFIX}must_be_unique", duplicates: duplicates))
      end
    end

    def clauses
      [
        Clause.new(CLAUSE_EQUALS, I18n.t("#{I18N_PREFIX}is"))
          .requires_inputs(["selected"])
          .with_meta({multiple: false}),

        Clause.new(CLAUSE_DOESNT_EQUAL, I18n.t("#{I18N_PREFIX}is_not"))
          .requires_inputs(["selected"])
          .with_meta({multiple: false}),

        Clause.new(CLAUSE_IN, I18n.t("#{I18N_PREFIX}is_one_of"))
          .requires_inputs(["selected"])
          .with_meta({multiple: true}),

        Clause.new(CLAUSE_NOT_IN, I18n.t("#{I18N_PREFIX}is_not_one_of"))
          .requires_inputs(["selected"])
          .with_meta({multiple: true}),

        Clause.new(CLAUSE_SET, I18n.t("#{I18N_PREFIX}is_set")),

        Clause.new(CLAUSE_NOT_SET, I18n.t("#{I18N_PREFIX}is_not_set"))
      ]
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
      value&.include? nil_option_id
    end

    def values_for_application(ids, single = false)
      # Get developer configured options with nil_option_id removed and select only elements from requested ids
      # Extract values from either _value key or id key. _value can be a callable
      values = get_options.call.delete_if { |el| el[:id] == nil_option_id }
        .select { |value| ids.include? value[:id] }
        .map! { |value| (value.has_key? :_value) ? call_proc_if_callable(value[:_value]) : value[:id] }
      single ? values[0] : values
    end

    def apply_condition(input, table, inverse_clause)
      attribute, value = arel_attribute(table), input[:selected]
      # TODO: Triggers on "through" relationship. Other relationships?
      @clause = CLAUSE_IN if inverse_clause

      case clause
      when CLAUSE_SET          then attribute.not_eq_any([nil, ""])
      when CLAUSE_NOT_SET      then attribute.eq_any([nil, ""])
      when CLAUSE_EQUALS       then apply_clause_equals(attribute, value)
      when CLAUSE_DOESNT_EQUAL then apply_clause_doesnt_equal(attribute, value)
      when CLAUSE_IN           then apply_clause_in(attribute, value)
      when CLAUSE_NOT_IN       then apply_clause_not_in(attribute, value)
      end.then { table.grouping _1 if _1 }
    end

    def apply_clause_in(attribute, value)
      normalized_values = values_for_application(value)

      if nil_option_selected?(value)
        attribute.in(normalized_values).or(attribute.eq(nil))
      else
        attribute.in(normalized_values)
      end
    end

    def apply_clause_not_in(attribute, value)
      normalized_values = values_for_application(value)
      # Must check for only nil option selected here
      if nil_option_selected?(value) && value.one?
        attribute.not_eq(nil)
      elsif nil_option_selected?(value)
        attribute.not_in(normalized_values).or(attribute.not_eq(nil))
      else
        attribute.not_in(normalized_values).or(attribute.eq(nil))
      end
    end

    def apply_clause_equals(attribute, value)
      if nil_option_selected?(value)
        attribute.eq(nil)
      else
        attribute.eq(values_for_application(value, true))
      end
    end

    def apply_clause_doesnt_equal(attribute, value)
      if nil_option_selected?(value)
        attribute.not_eq(nil)
      else
        attribute.not_eq(values_for_application(value, true)).or(attribute.eq(nil))
      end
    end
  end
end
