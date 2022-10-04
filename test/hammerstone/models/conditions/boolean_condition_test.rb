require "test_helper"
require "support/hammerstone/filter_test_helper"

module Hammerstone::Refine::Conditions
  describe BooleanCondition do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (test_bool boolean);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    it "shows_true_and_false_by_default" do
      skip "revisit purpose of this test"
    end

    describe "clause application" do
      it "handles clause true" do
        data = {clause: BooleanCondition::CLAUSE_TRUE}
        condition = BooleanCondition.new("test_bool").nulls_are_unknown.show_unknowns

        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."test_bool" = TRUE)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "handles clause false" do
        data = {clause: BooleanCondition::CLAUSE_FALSE}
        condition = BooleanCondition.new("test_bool").nulls_are_unknown.show_unknowns

        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."test_bool" = FALSE)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "handles clause not set" do
        data = {clause: BooleanCondition::CLAUSE_NOT_SET}
        condition = BooleanCondition.new("test_bool").nulls_are_unknown.show_unknowns

        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."test_bool" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "handles clause set" do
        data = {clause: BooleanCondition::CLAUSE_SET}
        condition = BooleanCondition.new("test_bool").nulls_are_unknown.show_unknowns
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."test_bool" IS NOT NULL)
        SQL

        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "handles true nulls" do
        data = {clause: BooleanCondition::CLAUSE_TRUE}
        condition = BooleanCondition.new("test_bool").nulls_are_true

        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."test_bool" = TRUE OR "t"."test_bool" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end

      it "handles false nulls" do
        data = {clause: BooleanCondition::CLAUSE_FALSE}
        condition = BooleanCondition.new("test_bool").nulls_are_false
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."test_bool" = FALSE OR "t"."test_bool" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition, data).to_sql
      end
    end
    describe "Human readable text representation" do
      it "correctly outputs human readable text for 'is set' clause" do
        data = {clause: BooleanCondition::CLAUSE_TRUE}
        condition = BooleanCondition.new("test_bool")
        condition.ensure_clauses.call
        filter = apply_condition_and_return_filter(condition, data)
        filter.translate_display(condition)

        assert_equal "Test Bool is true", condition.human_readable(data)
      end

      it "correctly outputs human readable text for 'is set' clause using remap" do
        data = {clause: BooleanCondition::CLAUSE_SET}
        condition = BooleanCondition.new("test_bool").only_clauses([BooleanCondition::CLAUSE_SET]).remap_clause_displays({st: "is defined"})
        filter = apply_condition_and_return_filter(condition, data)
        filter.translate_display(condition)

        assert_equal "Test Bool is defined", condition.human_readable(data)
      end
    end
  end
end
