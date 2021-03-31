require "test_helper"
require 'support/filter_test_helper'
require 'support/hammerstone/hammerstone_test_helper'

module Hammerstone::Refine::Conditions
  describe DateWithTimeCondition do
    include FilterTestHelper
    include ActiveSupport::Testing::TimeHelpers

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (date_test timestamp);")
      freeze_time do
        travel_to Time.zone.parse("2019-05-15 12:02:34 UTC")
        test.call
      end
      ApplicationRecord.connection.execute("DROP TABLE t;")
      DateCondition.class_variable_set :@@default_user_timezone, 'UTC'
      DateCondition.class_variable_set :@@default_database_timezone, 'UTC'
    end

    describe 'set attribute to datewithtime' do
      it 'correctly creates single day query' do
        condition = DateWithTimeCondition.new('date_test').attribute_is_date_with_time
        data = { clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: zulu('05/15/2019') }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 00:00:00' AND '2019-05-15 23:59:59.999999')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql

      end
    end

    describe 'user timezone' do
      it 'defaults to user timezone of utc' do
        condition = DateWithTimeCondition.new('date_test')
        data = { clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: zulu('05/15/2019') }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 00:00:00' AND '2019-05-15 23:59:59.999999')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'shifts query based on user timezone of America/Chicago' do
        condition = DateWithTimeCondition.new('date_test').with_user_timezone('America/Chicago')
        data = { clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: zulu('05/15/2019') }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 05:00:00' AND '2019-05-16 04:59:59.999999')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'can be set globally' do
        DateWithTimeCondition.default_user_timezone = 'America/Chicago'
        condition = DateWithTimeCondition.new('date_test')
        data = { clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: zulu('05/15/2019') }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 05:00:00' AND '2019-05-16 04:59:59.999999')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'can be a callback' do
        condition = DateWithTimeCondition.new('date_test')
        condition.with_user_timezone( Proc.new{'America/Chicago'} )
        data = { clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: zulu('05/15/2019') }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 05:00:00' AND '2019-05-16 04:59:59.999999')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end
    end

    describe 'database timezone' do
      it 'can be set and correctly shifts query' do
        condition = DateWithTimeCondition.new('date_test').with_database_timezone('America/Chicago')
        data = { clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: zulu('05/15/2019') }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-14 19:00:00' AND '2019-05-15 18:59:59.999999')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'can be set globally' do
        DateWithTimeCondition.default_database_timezone = 'America/Chicago'
        condition = DateWithTimeCondition.new('date_test')
        data = { clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: zulu('05/15/2019') }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-14 19:00:00' AND '2019-05-15 18:59:59.999999')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

    end

    describe 'both timezones' do
      it 'can set both database and user timezone' do
        condition = DateWithTimeCondition.new('date_test').with_user_timezone('America/Chicago').with_database_timezone('America/Toronto')
        data = { clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: zulu('05/15/2019') }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 01:00:00' AND '2019-05-16 00:59:59.999999')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end
    end

    describe 'simple clause test' do
      it 'executes clause between' do
        condition = DateWithTimeCondition.new('date_test')
        data = { clause: DateCondition::CLAUSE_BETWEEN, date1: zulu('05/15/2019'), date2: zulu('05/25/2019') }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 00:00:00' AND '2019-05-25 23:59:59.999999')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end
      it 'executes clause greater than ago' do
        condition = DateWithTimeCondition.new('date_test')
        data = { clause: DateCondition::CLAUSE_GREATER_THAN, days: 3, modifier: 'ago' }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" < '2019-05-12 12:02:34')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'executes clause greater than from now' do
        condition = DateWithTimeCondition.new('date_test')
        data = { clause: DateCondition::CLAUSE_GREATER_THAN, days: 3, modifier: 'from_now' }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" > '2019-05-18 12:02:34')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'executes clause less than ago' do
        condition = DateWithTimeCondition.new('date_test')
        data = { clause: DateCondition::CLAUSE_LESS_THAN, days: 3, modifier: 'ago' }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test"  > '2019-05-12 12:02:34')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'executes clause less than from now' do
        condition = DateWithTimeCondition.new('date_test')
        data = { clause: DateCondition::CLAUSE_LESS_THAN, days: 3, modifier: 'from_now' }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test"  < '2019-05-18 12:02:34')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'executes clause greater or equal' do
        condition = DateWithTimeCondition.new('date_test')
        data = { clause: DateCondition::CLAUSE_GREATER_THAN_OR_EQUAL, date1: zulu('05/15/2019') }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" >= '2019-05-15 12:02:34')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'executes clause less than or equal' do
        condition = DateWithTimeCondition.new('date_test')
        data = { clause: DateCondition::CLAUSE_LESS_THAN_OR_EQUAL, date1: zulu('05/15/2019') }
        expected_sql = <<~SQL.squish
                SELECT "t".* FROM "t" WHERE ("t"."date_test" <= '2019-05-15 12:02:34')
                SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end
    end
  end
end
