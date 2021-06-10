require "test_helper"
require "support/hammerstone/filter_test_helper"

module Hammerstone::Refine::Conditions
  describe DateCondition do
    include FilterTestHelper
    include ActiveSupport::Testing::TimeHelpers

    let(:condition) { DateCondition.new("date_to_test") }

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (date_to_test date);")
      freeze_time do
        travel_to Time.zone.parse("2019-05-15 UTC")
        test.call
      end
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    describe "date format validations" do
      it "throws errors for invalid date format for date1" do
        data = {clause: DateCondition::CLAUSE_EQUALS, date1: "05/15/2019"}
        exception =
          assert_raises Hammerstone::Refine::Conditions::Errors::ConditionClauseError do
            apply_condition_on_test_filter(condition, data)
          end
        assert_equal("[\"date1 is not a real date\"]", exception.message)
      end
    end

    describe "clause application" do
      it "correctly executes clause equals" do
        data = {clause: DateCondition::CLAUSE_EQUALS, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_to_test" = '2019-05-15')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "correctly executes clause doesnt equals" do
        data = {clause: DateCondition::CLAUSE_DOESNT_EQUAL, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_to_test" != '2019-05-15' OR "t"."date_to_test" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "correctly executes clause greater than or equal" do
        data = {clause: DateCondition::CLAUSE_GREATER_THAN_OR_EQUAL, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_to_test" >= '2019-05-15')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "correctly executes clause less than or equal" do
        data = {clause: DateCondition::CLAUSE_LESS_THAN_OR_EQUAL, date1: "2019-05-15"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."date_to_test" <= '2019-05-15')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      describe "Relative dates with modifiers" do
        before do
          @time = "2019-05-15 UTC"
        end

        it "correctly executes clause greater than 3 days ago" do
          data = {clause: DateCondition::CLAUSE_GREATER_THAN, days: "3", modifier: "ago"}
          expected_sql = <<~SQL.squish
            SELECT "t".* FROM "t" WHERE ("t"."date_to_test" < '2019-05-12')
          SQL
          assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
        end

        it "correctly executes clause greater than 3 days from now" do
          data = {clause: DateCondition::CLAUSE_GREATER_THAN, days: "3", modifier: "from_now"}
          expected_sql = <<~SQL.squish
            SELECT "t".* FROM "t" WHERE ("t"."date_to_test" > '2019-05-18')
          SQL
          assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
        end

        it "correctly executes clause exactly 3 days ago" do
          data = {clause: DateCondition::CLAUSE_EXACTLY, days: 3, modifier: "ago"}
          expected_sql = <<~SQL.squish
            SELECT "t".* FROM "t" WHERE ("t"."date_to_test" = '2019-05-12')
          SQL
          assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
        end

        it "correctly executes clause exactly 3 days from now" do
          data = {clause: DateCondition::CLAUSE_EXACTLY, days: 3, modifier: "from_now"}
          expected_sql = <<~SQL.squish
            SELECT "t".* FROM "t" WHERE ("t"."date_to_test" = '2019-05-18')
          SQL
          assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
        end

        it "correctly executes clause less than 3 days ago" do
          data = {clause: DateCondition::CLAUSE_LESS_THAN, days: 3, modifier: "ago"}
          expected_sql = <<~SQL.squish
            SELECT "t".* FROM "t" WHERE ("t"."date_to_test" > '2019-05-12')
          SQL
          assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
        end

        it "correctly executes clause less than 3 days from now" do
          data = {clause: DateCondition::CLAUSE_LESS_THAN, days: 3, modifier: "from_now"}
          expected_sql = <<~SQL.squish
            SELECT "t".* FROM "t" WHERE ("t"."date_to_test" < '2019-05-18')
          SQL
          assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
        end
      end

      describe "Between" do
        it "correctly executes clause between" do
          data = {clause: DateCondition::CLAUSE_BETWEEN, date1: "2019-05-15", date2: "2019-05-30"}
          expected_sql = <<~SQL.squish
            SELECT "t".* FROM "t" WHERE ("t"."date_to_test" BETWEEN '2019-05-15' AND '2019-05-30')
          SQL
          assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
        end

        it "throws error if dates are not in correct order" do
          skip "revist when finishing up validations"
          data = {clause: DateCondition::CLAUSE_BETWEEN, date1: "2019-05-15", date2: "05/30/2019"}
          exception =
            assert_raises Hammerstone::Refine::Conditions::Errors::ConditionClauseError do
              apply_condition_on_test_filter(condition, data)
            end
          assert_equal("[\"Dates must be sequential\"]", exception.message)
        end
      end

      describe "Set/Not Set" do
        it "executes set" do
          data = {clause: DateCondition::CLAUSE_SET}
          expected_sql = <<~SQL.squish
            SELECT "t".* FROM "t" WHERE ("t"."date_to_test" IS NOT NULL)
          SQL
          assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
        end

        it "executes not set" do
          data = {clause: DateCondition::CLAUSE_NOT_SET}
          expected_sql = <<~SQL.squish
            SELECT "t".* FROM "t" WHERE ("t"."date_to_test" IS NULL)
          SQL
          assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
        end
      end
    end
  end
end
