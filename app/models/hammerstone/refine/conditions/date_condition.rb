module Hammerstone::Refine::Conditions
  class DateCondition < Condition
    include HasClauses

    CLAUSE_EQUALS = Clauses::EQUALS
    CLAUSE_DOESNT_EQUAL = Clauses::DOESNT_EQUAL


    CLAUSE_LESS_THAN_OR_EQUAL = Clauses::LESS_THAN_OR_EQUAL
    CLAUSE_BETWEEN = Clauses::BETWEEN
    CLAUSE_GREATER_THAN_OR_EQUAL = Clauses::GREATER_THAN_OR_EQUAL

    CLAUSE_LESS_THAN = Clauses::LESS_THAN
    CLAUSE_EXACTLY = Clauses::EXACTLY
    CLAUSE_GREATER_THAN = Clauses::GREATER_THAN

    CLAUSE_SET = Clauses::SET
    CLAUSE_NOT_SET = Clauses::NOT_SET

    ATTRIBUTE_TYPE_DATE = 0
    ATTRIBUTE_TYPE_DATE_WITH_TIME = 1
    ATTRIBUTE_TYPE_UNIX_TIMESTAMP = 2

    cattr_accessor :default_user_timezone, instance_accessor: false
    cattr_accessor :default_database_timezone, instance_accessor: false

    def boot
      @attribute_type = @attribute_type ||= ATTRIBUTE_TYPE_DATE
      @@default_user_timezone ||= 'UTC'
      @@default_database_timezone ||= 'UTC'
      # TODO: revisit during validations
      # add_rules(
      #   date1: ['nullable', 'date'],
      #   date2: ['nullable', 'date'],
      #   days: ['nullable', 'integer']
      # )
      # this.addEnsurance ensureTimezones
    end

    def component
      'date-condition'
    end

    def attribute_is_date
      attribute_is(ATTRIBUTE_TYPE_DATE)
      self
    end

    def attribute_is_date_with_time
      attribute_is(ATTRIBUTE_TYPE_DATE_WITH_TIME)
      self
    end

    def attribute_is_unix_timestamp #time
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

    def user_timezone
      @user_timezone ||= @@default_user_timezone
    end

    def database_timezone
      @database_timezone ||= @@default_database_timezone
    end

    def clauses
      [
        Clause.new(CLAUSE_EQUALS, 'Is Equal To')
                .requires_inputs('date1'),

        Clause.new(CLAUSE_DOESNT_EQUAL, 'Is Not Equal To')
            .requires_inputs('date1'),

        Clause.new(CLAUSE_LESS_THAN_OR_EQUAL, 'Is On or Before')
            .requires_inputs('date1'),

        Clause.new(CLAUSE_GREATER_THAN_OR_EQUAL, 'Is On or After')
            .requires_inputs('date1'),

        Clause.new(CLAUSE_BETWEEN, 'Is Between')
            .requires_inputs(['date1', 'date2']),

        Clause.new(CLAUSE_GREATER_THAN, 'Is More Than')
            .requires_inputs(['days', 'modifier']),

        Clause.new(CLAUSE_EXACTLY, 'Is Exactly')
            .requires_inputs(['days', 'modifier']),

        Clause.new(CLAUSE_LESS_THAN, 'Is Less Than')
            .requires_inputs(['days', 'modifier']),

        Clause.new(CLAUSE_SET, 'Is Set'),

        Clause.new(CLAUSE_NOT_SET, 'Is Not Set'),

      ]
    end

    def relative_clauses
      [CLAUSE_GREATER_THAN, CLAUSE_LESS_THAN, CLAUSE_EXACTLY]
    end

    def is_relative_clause?(clause)
      relative_clauses.include?(clause)
    end

    def apply_condition(input, table)
      clause = input[:clause]

      date1 = Date.parse(input[:date1]) if input[:date1]
      date2 = Date.parse(input[:date2]) if input[:date2]

      if is_relative_clause?(clause)
        date1 = comparison_date(input)
        clause = standardize_clause(clause, input)
      end
      # Allow for custom clauses
      if @attribute_type == ATTRIBUTE_TYPE_DATE
        apply_standardized_values(table, date1, date2, clause)
      else
        apply_standardized_values_with_time(table, date1, date2, clause)
      end
    end

    def comparison_date(input)
      days = input[:days].to_i
      modifier = input[:modifier]

      # If the user has requested a certain number of days 'ago',then value
      # needs to be negative

      if modifier == 'ago'
        days *=- 1
      end
      date1 = Date.current + days
    end

    def standardize_clause(clause, input)
      modifier = input[:modifier]
      case clause
      when CLAUSE_GREATER_THAN
        modifier == 'ago' ? CLAUSE_LESS_THAN : CLAUSE_GREATER_THAN
      when CLAUSE_LESS_THAN
        modifier == 'ago' ? CLAUSE_GREATER_THAN : CLAUSE_LESS_THAN
      when CLAUSE_EXACTLY
        CLAUSE_EQUALS
      end
    end

     def start_of_day(day)
      # Coerce date object into ActiveSupport::TimeWithZone object
      # Returns the day at 00 user time
      day_in_user_tz = day.in_time_zone(user_timezone)
      # Gets the day in database time
      database_local = day_in_user_tz.in_time_zone(database_timezone)
      # Gets database UTC offset
      offset = database_local.utc_offset
      # AREL will convert to UTC before seaching, so add offset to account for db timezone
      utc_start = database_local.in_time_zone('UTC')
      utc_start + offset
    end

    def end_of_day(day)
      day_in_user_tz = day.in_time_zone(user_timezone)
      end_of_day = day_in_user_tz.end_of_day
      database_local = end_of_day.in_time_zone(database_timezone)
      offset = database_local.utc_offset
      utc_end = database_local.in_time_zone('UTC')
      utc_end + offset
    end

    def comparison_time(day)
      # If comparison request, compare to time request is made
      current_time = Time.current.in_time_zone(user_timezone)
      # Day will be 00 based
      day_in_user_tz = day.in_time_zone(user_timezone)
      options = { hour: current_time.hour, min: current_time.min, sec: current_time.sec }
      # The queried day shifted to local time hour::min::sec
      day_time_shifted = day_in_user_tz.change(options)

      database_local = day_time_shifted.in_time_zone(database_timezone)
      offset = database_local.utc_offset
      utc_comparison_time = database_local.in_time_zone('UTC')
      utc_comparison_time + offset
    end

    def apply_standardized_values_with_time(table, date1, date2, clause)

      case clause
      when CLAUSE_EQUALS
        apply_clause_between(table, start_of_day(date1), end_of_day(date1))
      when CLAUSE_BETWEEN
        apply_clause_between(table, start_of_day(date1), end_of_day(date2))
      when CLAUSE_LESS_THAN
        apply_clause_less_than(comparison_time(date1), table)
      when CLAUSE_GREATER_THAN
        apply_clause_greater_than(comparison_time(date1), table)
      when CLAUSE_GREATER_THAN_OR_EQUAL
        apply_clause_greater_than_or_equal(comparison_time(date1), table)
      when CLAUSE_LESS_THAN_OR_EQUAL
        apply_clause_less_than_or_equal(comparison_time(date1), table)
      end
    end

    def apply_standardized_values(table, date1, date2, clause)

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

      when CLAUSE_SET
        apply_clause_set(table)

      when CLAUSE_NOT_SET
        apply_clause_not_set(table)
      end
    end

    def apply_clause_between(table, date1, date2)
      table.grouping(table[:"#{attribute}"].between(date1..date2))
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