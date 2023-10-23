require "test_helper"
require "support/refine/filter_test_helper"

module Refine::Conditions
  describe DateWithTimeCondition do
    include FilterTestHelper
    include ActiveSupport::Testing::TimeHelpers

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (date_test datetime(6));")
      freeze_time do
        travel_to Time.zone.parse("2019-05-15 12:02:34 UTC")
        test.call
      end
      ApplicationRecord.connection.execute("DROP TABLE t;")
      DateCondition.class_variable_set :@@default_user_timezone, "UTC"
      DateCondition.class_variable_set :@@default_database_timezone, "UTC"
    end

    describe "set attribute to datewithtime" do
      it "correctly creates single day query" do
        condition = DateWithTimeCondition.new("date_test").attribute_is_date_with_time
        data = {clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 00:00:00' AND '2019-05-15 23:59:59.999999')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end
    end

    describe "user timezone" do
      it "defaults to user timezone of utc" do
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 00:00:00' AND '2019-05-15 23:59:59.999999')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "shifts query based on user timezone of America/Chicago" do
        condition = DateWithTimeCondition.new("date_test").with_user_timezone("America/Chicago")
        data = {clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 05:00:00' AND '2019-05-16 04:59:59.999999')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "can be set globally" do
        DateWithTimeCondition.default_user_timezone = "America/Chicago"
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 05:00:00' AND '2019-05-16 04:59:59.999999')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "can be a callback" do
        condition = DateWithTimeCondition.new("date_test")
        condition.with_user_timezone(proc { "America/Chicago" })
        data = {clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 05:00:00' AND '2019-05-16 04:59:59.999999')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end
    end

    describe "database timezone" do
      it "can be set and correctly shifts query" do
        condition = DateWithTimeCondition.new("date_test").with_database_timezone("America/Chicago")
        data = {clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-14 19:00:00' AND '2019-05-15 18:59:59.999999')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "can be set globally" do
        DateWithTimeCondition.default_database_timezone = "America/Chicago"
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-14 19:00:00' AND '2019-05-15 18:59:59.999999')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end
    end

    describe "both timezones" do
      it "can set both database and user timezone" do
        condition = DateWithTimeCondition.new("date_test").with_user_timezone("America/Chicago").with_database_timezone("America/Toronto")
        data = {clause: DateWithTimeCondition::CLAUSE_EQUALS, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 01:00:00' AND '2019-05-16 00:59:59.999999')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end
    end

    describe "simple clause test" do
      it "executes clause between" do
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateCondition::CLAUSE_BETWEEN, date1: "2019-05-15", date2: "2019-05-25"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" BETWEEN '2019-05-15 00:00:00' AND '2019-05-25 23:59:59.999999')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "executes clause not between" do
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateCondition::CLAUSE_NOT_BETWEEN, date1: "2019-05-15", date2: "2019-05-25"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" < '2019-05-15 00:00:00' OR "t"."date_test" > '2019-05-25 23:59:59.999999')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "correctly executes clause doesnt equals" do
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateCondition::CLAUSE_DOESNT_EQUAL, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" < '2019-05-15 00:00:00' OR "t"."date_test" > '2019-05-15 23:59:59.999999')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "executes clause greater than ago" do
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateCondition::CLAUSE_GREATER_THAN, days: 3, modifier: "ago"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" < '2019-05-12 12:02:34')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "executes clause greater than from now" do
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateCondition::CLAUSE_GREATER_THAN, days: 3, modifier: "from_now"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" > '2019-05-18 12:02:34')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "executes clause less than ago" do
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateCondition::CLAUSE_LESS_THAN, days: 3, modifier: "ago"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test"  > '2019-05-12 12:02:34')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "executes clause less than from now" do
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateCondition::CLAUSE_LESS_THAN, days: 3, modifier: "from_now"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test"  < '2019-05-18 12:02:34')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "executes clause greater or equal" do
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateCondition::CLAUSE_GREATER_THAN_OR_EQUAL, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" >= '2019-05-15 12:02:34')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "executes clause less than or equal" do
        condition = DateWithTimeCondition.new("date_test")
        data = {clause: DateCondition::CLAUSE_LESS_THAN_OR_EQUAL, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_test" <= '2019-05-15 12:02:34')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      describe 'date_lte_uses_eod set' do
        before do
          @date_lte_uses_eod_was = Refine::Rails.configuration.date_lte_uses_eod
          Refine::Rails.configuration.date_lte_uses_eod = true
        end

        after do
          Refine::Rails.configuration.date_lte_uses_eod = @date_lte_uses_eod_was
        end

        it 'uses end of day for clause less than or equal' do
         condition = DateWithTimeCondition.new("date_test")
         data = {clause: DateCondition::CLAUSE_LESS_THAN_OR_EQUAL, date1: "2019-05-15"}
         expected_sql = <<~SQL.squish
           SELECT "t".* FROM "t" WHERE ("t"."date_test" <= '2019-05-15 23:59:59.999999')
         SQL
         assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql 
        end
      end

      describe 'date_gte_uses_bod set' do
        before do
          @date_gte_uses_bod_was = Refine::Rails.configuration.date_gte_uses_bod
          Refine::Rails.configuration.date_gte_uses_bod = true
        end

        after do
          Refine::Rails.configuration.date_gte_uses_bod = @date_gte_uses_bod_was
        end

        it 'uses end of day for clause greater than or equal' do
         condition = DateWithTimeCondition.new("date_test")
         data = {clause: DateCondition::CLAUSE_GREATER_THAN_OR_EQUAL, date1: "2019-05-15"}
         expected_sql = <<~SQL.squish
           SELECT "t".* FROM "t" WHERE ("t"."date_test" >= '2019-05-15 00:00:00')
         SQL
         assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql 
        end
      end

      describe "Human readable text representation" do
        it "correctly outputs human readable text for 'is set' clause" do
          condition = DateWithTimeCondition.new("date_test")
          data = {clause: DateCondition::CLAUSE_SET}
          filter = apply_condition_and_return_filter(condition, data)
          filter.translate_display(condition)
          assert_equal "Date Test is set", condition.human_readable(data)
        end

        it "correctly outputs human readable text for 'is between' clause" do
          condition = DateWithTimeCondition.new("date_test")
          data = {clause: DateCondition::CLAUSE_BETWEEN, date1: "2019-05-15", date2: "2019-06-15" }
          filter = apply_condition_and_return_filter(condition, data)
          filter.translate_display(condition)
          assert_equal "Date Test is between 05/15/19 and 06/15/19", condition.human_readable(data)
        end
      end

      describe "with timezone set to true" do
        describe "With a standard Time Zone that outputs an abbreviation" do
          before do
            DateWithTimeCondition.default_user_timezone = "Hawaii" # Hawaii is a static timezone that does not change (No daylight savings)
          end

          it "correctly outputs human readable text for 'is set' clause without timezone since it's not applicable" do
            condition = DateWithTimeCondition.new("date_test").with_human_readable_timezone(true)
            data = {clause: DateCondition::CLAUSE_SET}
            filter = apply_condition_and_return_filter(condition, data)
            filter.translate_display(condition)
            assert_equal "Date Test is set", condition.human_readable(data)
          end

          it "correctly outputs human readable text for 'CLAUSE_BETWEEN' clause with timezone" do
            condition = DateWithTimeCondition.new("date_test").with_human_readable_timezone(true)
            data = {clause: DateCondition::CLAUSE_BETWEEN, date1: "2019-05-15", date2: "2019-06-15" }
            filter = apply_condition_and_return_filter(condition, data)
            filter.translate_display(condition)
            assert_equal "Date Test is between 05/15/19 and 06/15/19 (HST)", condition.human_readable(data)
          end

          it "correctly outputs human readable text for 'CLAUSE_LESS_THAN_OR_EQUAL' clause with timezone" do
            condition = DateWithTimeCondition.new("date_test").with_human_readable_timezone(true)
            data = {clause: DateCondition::CLAUSE_LESS_THAN_OR_EQUAL, date1: "2019-05-15" }
            filter = apply_condition_and_return_filter(condition, data)
            filter.translate_display(condition)
            assert_equal "Date Test is on or before 05/15/19 (HST)", condition.human_readable(data)
          end

          it "correctly outputs human readable text for 'CLAUSE_GREATER_THAN' clause with timezone" do
            condition = DateWithTimeCondition.new("date_test").with_human_readable_timezone(true)
            data = {clause: DateCondition::CLAUSE_GREATER_THAN, days: 5 }
            filter = apply_condition_and_return_filter(condition, data)
            filter.translate_display(condition)
            assert_equal "Date Test is more than 5 days from now (HST)", condition.human_readable(data)
          end
        end

        describe "Nonstandard time zone abbreviation" do
          it "correctly outputs human readable text for 'CLAUSE_BETWEEN' clause with International Date Line West timezone" do
            DateWithTimeCondition.default_user_timezone = "International Date Line West"
            condition = DateWithTimeCondition.new("date_test").with_human_readable_timezone(true)
            data = {clause: DateCondition::CLAUSE_BETWEEN, date1: "2019-05-15", date2: "2019-06-15" }
            filter = apply_condition_and_return_filter(condition, data)
            filter.translate_display(condition)
            assert_equal "Date Test is between 05/15/19 and 06/15/19 (GMT-12:00)", condition.human_readable(data)
          end

          it "correctly outputs human readable text for 'CLAUSE_BETWEEN' clause with  timezone" do
            DateWithTimeCondition.default_user_timezone = "Kathmandu"
            condition = DateWithTimeCondition.new("date_test").with_human_readable_timezone(true)
            data = {clause: DateCondition::CLAUSE_BETWEEN, date1: "2019-05-15", date2: "2019-06-15" }
            filter = apply_condition_and_return_filter(condition, data)
            filter.translate_display(condition)
            assert_equal "Date Test is between 05/15/19 and 06/15/19 (GMT+05:45)", condition.human_readable(data)
          end
        end
      end
    end
  end
end
