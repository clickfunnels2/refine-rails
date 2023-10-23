require "test_helper"
require "support/refine/filter_test_helper"

module Refine::Conditions
  describe NumericCondition do
    include FilterTestHelper

    let(:condition) { NumericCondition.new("numeric_test") }

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (numeric_test integer, numeric_float float);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    it "adds error if value is float without explicitly setting floats" do
      data = {clause: NumericCondition::CLAUSE_EQUALS, value1: 5.3}
      filter = apply_condition_and_return_filter(condition, data)
      assert_equal(["Value1 must be an integer"], filter.errors.full_messages)
    end

    it "allows floats if floats are set" do
      float_condition = NumericCondition.new("numeric_float").allow_floats
      data = {clause: NumericCondition::CLAUSE_EQUALS, value1: 5.3}
      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."numeric_float" = 5.3)
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(float_condition, data).to_sql
    end

    it "handles clause EQUALS" do
      data = {clause: NumericCondition::CLAUSE_EQUALS, value1: 5}

      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."numeric_test" = 5)
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
    end

    it "handles clause GREATER THAN" do
      data = {clause: NumericCondition::CLAUSE_GREATER_THAN, value1: 5}

      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."numeric_test" > 5)
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
    end

    it "handles clause GREATER THAN OR EQUAL" do
      data = {clause: NumericCondition::CLAUSE_GREATER_THAN_OR_EQUAL, value1: 5}

      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."numeric_test" >= 5)
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
    end

    it "handles clause LESS THAN" do
      data = {clause: NumericCondition::CLAUSE_LESS_THAN, value1: 5}

      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."numeric_test" < 5)
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
    end

    it "handles clause LESS THAN OR EQUAL" do
      data = {clause: NumericCondition::CLAUSE_LESS_THAN_OR_EQUAL, value1: 5}

      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."numeric_test" <= 5)
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
    end

    it "handles clause CLAUSE BETWEEN" do
      data = {clause: NumericCondition::CLAUSE_BETWEEN, value1: 5, value2: 10}

      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."numeric_test" BETWEEN 5 AND 10)
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
    end

    it "handles clause CLAUSE SET" do
      data = {clause: NumericCondition::CLAUSE_SET}

      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."numeric_test" IS NOT NULL)
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
    end

    it "handles clause CLAUSE NOT SET" do
      data = {clause: NumericCondition::CLAUSE_NOT_SET}

      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."numeric_test" IS NULL)
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
    end

    it "handles clause CLAUSE DOESNT EQUAL" do
      data = {clause: NumericCondition::CLAUSE_DOESNT_EQUAL, value1: 5}

      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."numeric_test" != 5 OR "t"."numeric_test" IS NULL)
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
    end

    it "handles clause CLAUSE NOT BETWEEN" do
      data = {clause: NumericCondition::CLAUSE_NOT_BETWEEN, value1: 5, value2: 10}

      expected_sql = <<~SQL.squish
        SELECT \"t\".* FROM \"t\" WHERE (\"t\".\"numeric_test\" < 5 OR \"t\".\"numeric_test\" > 10)
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
    end

    describe "Human readable text representation" do
      it "correctly outputs human readable text for 'is set' clause" do
        data = {clause: NumericCondition::CLAUSE_SET}
        filter = apply_condition_and_return_filter(condition, data)
        filter.translate_display(condition)
        assert_equal "Numeric Test is set", condition.human_readable(data)
      end

      it "correctly outputs human readable text for 'equals' clause using remap" do
        data = {clause: NumericCondition::CLAUSE_EQUALS, value1: 42}
        condition = NumericCondition.new("numeric_test").remap_clause_displays({eq: "equals"})
        filter = apply_condition_and_return_filter(condition, data)
        filter.translate_display(condition)

        assert_equal "Numeric Test equals 42", condition.human_readable(data)
      end
    end
  end
end
