module Hammerstone::Refine::Conditions
  class DateCondition < Condition
    include ActiveModel::Validations
    include HasClauses

    validate :date1_must_be_real, :date2_must_be_real

    cattr_accessor :default_user_timezone, default: "UTC", instance_accessor: false
    cattr_accessor :default_database_timezone, default: "UTC", instance_accessor: false
    attr_reader :date1, :date2, :days

    CLAUSE_EQUALS = Clauses::EQUALS
    CLAUSE_DOESNT_EQUAL = Clauses::DOESNT_EQUAL

    CLAUSE_LESS_THAN = Clauses::LESS_THAN
    CLAUSE_LESS_THAN_OR_EQUAL = Clauses::LESS_THAN_OR_EQUAL

    CLAUSE_GREATER_THAN = Clauses::GREATER_THAN
    CLAUSE_GREATER_THAN_OR_EQUAL = Clauses::GREATER_THAN_OR_EQUAL

    CLAUSE_BETWEEN = Clauses::BETWEEN
    CLAUSE_NOT_BETWEEN = Clauses::NOT_BETWEEN

    CLAUSE_EXACTLY = Clauses::EXACTLY
    CLAUSE_SET = Clauses::SET
    CLAUSE_NOT_SET = Clauses::NOT_SET

    ATTRIBUTE_TYPE_DATE = 0
    ATTRIBUTE_TYPE_DATE_WITH_TIME = 1
    ATTRIBUTE_TYPE_UNIX_TIMESTAMP = 2

    I18N_PREFIX = "hammerstone.refine_blueprints.date_condition."

    def date1_must_be_real
      return true unless date1
      begin
        Date.strptime(date1, "%Y-%m-%d")
      rescue ArgumentError
        errors.add(:base, I18n.t("#{I18N_PREFIX}date1_error"))
        false
      end
    end

    def date2_must_be_real
      return true unless date2
      begin
        Date.strptime(date2, "%Y-%m-%d")
      rescue ArgumentError
        errors.add(:base, I18n.t("#{I18N_PREFIX}date2_error"))
        false
      end
    end

    def boot
      @attribute_type = @attribute_type ||= ATTRIBUTE_TYPE_DATE
      add_ensurance(ensure_timezone)
    end

    def set_input_parameters(input)
      @date1 = input[:date1]
      @date2 = input[:date2]
      @days = input[:days]
    end

    def ensure_timezone
      proc do
        timezone_exists(database_timezone)
        timezone_exists(user_timezone)
      end
    end

    def timezone_exists(zone)
      return if ActiveSupport::TimeZone[zone].present?
      errors.add(:base, I18n.t("#{I18N_PREFIX}timezone_error", zone: zone))
    end

    def component
      "date-condition"
    end

    def human_readable(input)
      current_clause = get_clause_by_id(input[:clause])

      case input[:clause]
      when *[CLAUSE_EQUALS, CLAUSE_DOESNT_EQUAL, CLAUSE_LESS_THAN_OR_EQUAL, CLAUSE_GREATER_THAN_OR_EQUAL]
        formatted_date1 = I18n.l(input[:date1].to_date, format: :dmy)
        "#{display} #{current_clause.display} #{formatted_date1}"
      when *[CLAUSE_BETWEEN, CLAUSE_NOT_BETWEEN]
        formatted_date1 = I18n.l(input[:date1].to_date, format: :dmy)
        formatted_date2 = I18n.l(input[:date2].to_date, format: :dmy)
        and_i18n = I18n.t("#{I18N_PREFIX}and")
        "#{display} #{current_clause.display} #{formatted_date1} #{and_i18n} #{formatted_date2}"
      when *[CLAUSE_GREATER_THAN, CLAUSE_LESS_THAN, CLAUSE_EXACTLY]
        days_i18n = I18n.t("#{I18N_PREFIX}and")
        ago_i18n = I18n.t("#{I18N_PREFIX}days")
        from_now_i18n = I18n.t("#{I18N_PREFIX}ago")
        "#{display} #{current_clause.display} #{input[:days]} #{days_i18n} #{input[:modifier] == 'ago' ? ago_i18n : from_now_i18n}"
      when *[CLAUSE_SET, CLAUSE_NOT_SET]
        "#{display} #{current_clause.display}"
      else
        not_supported_i18n = I18n.t("#{I18N_PREFIX}not_supported")
        raise "#{input[:clause]} #{not_supported_i18n}"
      end
    end

    def human_readable_value(input)
      current_clause = get_clause_by_id(input[:clause])

      case input[:clause]
      when *[CLAUSE_EQUALS, CLAUSE_DOESNT_EQUAL, CLAUSE_LESS_THAN_OR_EQUAL, CLAUSE_GREATER_THAN_OR_EQUAL]
        formatted_date1 = I18n.l(input[:date1].to_date, format: :dmy)
        formatted_date1
      when *[CLAUSE_BETWEEN, CLAUSE_NOT_BETWEEN]
        formatted_date1 = I18n.l(input[:date1].to_date, format: :dmy)
        formatted_date2 = I18n.l(input[:date2].to_date, format: :dmy)
        and_i18n = I18n.t("#{I18N_PREFIX}and")
        "#{formatted_date1} #{and_i18n} #{formatted_date2}"
      when *[CLAUSE_GREATER_THAN, CLAUSE_LESS_THAN, CLAUSE_EXACTLY]
        days_i18n = I18n.t("#{I18N_PREFIX}and")
        ago_i18n = I18n.t("#{I18N_PREFIX}days")
        from_now_i18n = I18n.t("#{I18N_PREFIX}ago")
        "#{input[:days]} #{days_i18n} #{input[:modifier] == 'ago' ? ago_i18n : from_now_i18n}"
      when *[CLAUSE_SET, CLAUSE_NOT_SET]
        ""
      else
        not_supported_i18n = I18n.t("#{I18N_PREFIX}not_supported")
        raise "#{input[:clause]} #{not_supported_i18n}"
      end
    end

    def attribute_is_date
      attribute_is(ATTRIBUTE_TYPE_DATE)
      self
    end

    def attribute_is_date_with_time
      attribute_is(ATTRIBUTE_TYPE_DATE_WITH_TIME)
      self
    end

    def attribute_is_unix_timestamp # time
      attribute_is(ATTRIBUTE_TYPE_UNIX_TIMESTAMP)
    end

    def attribute_is(type)
      @attribute_type = type
      self
    end

    def with_database_timezone(timezone)
      @database_timezone = timezone
      self
    end

    def with_user_timezone(timezone)
      @user_timezone = timezone
      self
    end

    def get_timezone(zone)
      call_proc_if_callable(zone)
    end

    def user_timezone
      get_timezone(@user_timezone ||= @@default_user_timezone)
    end

    def database_timezone
      get_timezone(@database_timezone ||= @@default_database_timezone)
    end

    def clauses
      [
        Clause.new(CLAUSE_EQUALS, I18n.t("#{I18N_PREFIX}is_on"))
          .requires_inputs("date1"),

        Clause.new(CLAUSE_DOESNT_EQUAL, I18n.t("#{I18N_PREFIX}not_on"))
          .requires_inputs("date1"),

        Clause.new(CLAUSE_LESS_THAN_OR_EQUAL, I18n.t("#{I18N_PREFIX}is_on_or_before"))
          .requires_inputs("date1"),

        Clause.new(CLAUSE_GREATER_THAN_OR_EQUAL, I18n.t("#{I18N_PREFIX}is_on_or_after"))
          .requires_inputs("date1"),

        Clause.new(CLAUSE_BETWEEN, I18n.t("#{I18N_PREFIX}is_between"))
          .requires_inputs(["date1", "date2"]),

        Clause.new(CLAUSE_NOT_BETWEEN, I18n.t("#{I18N_PREFIX}is_not_between"))
          .requires_inputs(["date1", "date2"]),

        Clause.new(CLAUSE_GREATER_THAN, I18n.t("#{I18N_PREFIX}is_more_than"))
          .requires_inputs(["days", "modifier"]),

        Clause.new(CLAUSE_EXACTLY, I18n.t("#{I18N_PREFIX}is"))
          .requires_inputs(["days", "modifier"]),

        Clause.new(CLAUSE_LESS_THAN, I18n.t("#{I18N_PREFIX}is_less_than"))
          .requires_inputs(["days", "modifier"]),

        Clause.new(CLAUSE_SET, I18n.t("#{I18N_PREFIX}is_set")),

        Clause.new(CLAUSE_NOT_SET, I18n.t("#{I18N_PREFIX}is_not_set")),
      ]
    end

    def relative_clauses
      [CLAUSE_GREATER_THAN, CLAUSE_LESS_THAN, CLAUSE_EXACTLY]
    end

    def is_relative_clause?
      relative_clauses.include? clause
    end

    def modify_date_and_clause!(input)
      @date1 = comparison_date(input)
      @clause = standardize_clause(input)
    end

    def apply_condition(input, table, _inverse_clause)
      if clause == CLAUSE_SET
        return apply_clause_set(table)
      end

      if clause == CLAUSE_NOT_SET
        return apply_clause_not_set(table)
      end

      modify_date_and_clause!(input) if is_relative_clause?

      # TODO: Allow for custom clauses
      if @attribute_type == ATTRIBUTE_TYPE_DATE
        apply_standardized_values(table)
      else
        apply_standardized_values_with_time(table)
      end
    end

    def comparison_date(input)
      modified_days = days.to_i
      modifier = input[:modifier]

      # If the user has requested a certain number of days 'ago',then value
      # needs to be negative

      if modifier == "ago"
        modified_days *= - 1
      end
      (Date.current + modified_days).strftime("%Y-%m-%d")
    end

    def standardize_clause(input)
      modifier = input[:modifier]
      case clause
      when CLAUSE_GREATER_THAN
        modifier == "ago" ? CLAUSE_LESS_THAN : CLAUSE_GREATER_THAN
      when CLAUSE_LESS_THAN
        modifier == "ago" ? CLAUSE_GREATER_THAN : CLAUSE_LESS_THAN
      when CLAUSE_EXACTLY
        CLAUSE_EQUALS
      end
    end

    def start_of_day(day)
      # Returns the start of day in the user timezone
      # Day shifted to user time zone 00 based
      day_in_user_tz = day.in_time_zone(user_timezone).beginning_of_day

      # Get day_in_user_tz in database time zone
      database_local = day_in_user_tz.in_time_zone(database_timezone)

      offset = database_local.utc_offset
      # Arel will convert to UTC before seaching, so add offset to account for db timezone
      utc_start = database_local.in_time_zone("UTC")
      utc_start + offset
    end

    def end_of_day(day)
      day_in_user_tz = day.in_time_zone(user_timezone)
      end_of_day = day_in_user_tz.end_of_day
      database_local = end_of_day.in_time_zone(database_timezone)
      offset = database_local.utc_offset
      utc_end = database_local.in_time_zone("UTC")
      utc_end + offset
    end

    def comparison_time(day)
      # If comparison request, compare to the time the request is made (such as 3 days ago)
      current_time = Time.current.in_time_zone(user_timezone)

      # Day will be 00 based
      day_in_user_tz = day.to_time(:utc).in_time_zone(user_timezone)

      options = {hour: current_time.hour, min: current_time.min, sec: current_time.sec}

      # The queried day shifted to local time hour::min::sec
      day_time_shifted = day_in_user_tz.change(options)

      database_local = day_time_shifted.in_time_zone(database_timezone)
      offset = database_local.utc_offset
      utc_comparison_time = database_local.in_time_zone("UTC")
      utc_comparison_time + offset
    end

    def apply_standardized_values_with_time(table)
      case clause
      # At this point, `between` and `equal` are functionally the
      # same, i.e. they are querying between two _times_.
      when CLAUSE_EQUALS
        apply_clause_between(table, start_of_day(date1), end_of_day(date1))
      when CLAUSE_BETWEEN
        apply_clause_between(table, start_of_day(date1), end_of_day(date2))

      when CLAUSE_DOESNT_EQUAL
        apply_clause_not_between(table, start_of_day(date1), end_of_day(date1))
      when CLAUSE_NOT_BETWEEN
        apply_clause_not_between(table, start_of_day(date1), end_of_day(date2))


      when CLAUSE_LESS_THAN
        apply_clause_less_than(comparison_time(date1), table)
      when CLAUSE_GREATER_THAN
        apply_clause_greater_than(comparison_time(date1), table)
      when CLAUSE_GREATER_THAN_OR_EQUAL
        if Refine::Rails.configuration.date_gte_uses_bod
          datetime = start_of_day(date1)
        else
          datetime = comparison_time(date1)
        end
        apply_clause_greater_than_or_equal(datetime, table)
      when CLAUSE_LESS_THAN_OR_EQUAL
        if Refine::Rails.configuration.date_lte_uses_eod
          datetime = end_of_day(date1)
        else
          datetime = comparison_time(date1)
        end
        apply_clause_less_than_or_equal(datetime, table)
      end

    end

    def apply_standardized_values(table)
      case clause
      when CLAUSE_EQUALS
        apply_clause_equals(date1, table)

      when CLAUSE_DOESNT_EQUAL
        apply_clause_doesnt_equal(date1, table)

      when CLAUSE_LESS_THAN
        apply_clause_less_than(date1, table)

      when CLAUSE_GREATER_THAN
        apply_clause_greater_than(date1, table)

      when CLAUSE_GREATER_THAN_OR_EQUAL
        apply_clause_greater_than_or_equal(date1, table)

      when CLAUSE_LESS_THAN_OR_EQUAL
        apply_clause_less_than_or_equal(date1, table)

      when CLAUSE_BETWEEN
        apply_clause_between(table, date1, date2)
      end
    end

    def apply_clause_between(table, first_date, second_date)
      table.grouping(table[:"#{attribute}"].between(first_date..second_date))
    end

    def apply_clause_not_between(table, first_date, second_date)
      table.grouping(table[:"#{attribute}"].not_between(first_date..second_date))
    end

    def apply_clause_equals(value, table)
      table.grouping(table[:"#{attribute}"].eq(value))
    end

    def apply_clause_doesnt_equal(value, table)
      table.grouping(table[:"#{attribute}"].not_eq(value).or(table[:"#{attribute}"].eq(nil)))
    end

    def apply_clause_greater_than(value, table)
      table.grouping(table[:"#{attribute}"].gt(value))
    end

    def apply_clause_greater_than_or_equal(value, table)
      table.grouping(table[:"#{attribute}"].gteq(value))
    end

    def apply_clause_less_than(value, table)
      table.grouping(table[:"#{attribute}"].lt(value))
    end

    def apply_clause_less_than_or_equal(value, table)
      table.grouping(table[:"#{attribute}"].lteq(value))
    end

    def apply_clause_set(table)
      table.grouping(table[:"#{attribute}"].not_eq(nil))
    end

    def apply_clause_not_set(table)
      table.grouping(table[:"#{attribute}"].eq(nil))
    end
  end
end
