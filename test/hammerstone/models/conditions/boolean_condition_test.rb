require "test_helper"
require 'support/filter_test_helper'

module Hammerstone::Refine::Conditions
  describe BooleanCondition do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (test_bool boolean);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    it 'shows_true_and_false_by_default' do
      skip 'learn more about clauses'
      condition = BooleanCondition.new('boolean_test')
    end

    describe 'clause application' do
      it 'handles clause true' do
        data = { clause: BooleanCondition::CLAUSE_TRUE }
        condition = BooleanCondition.new('test_bool').nulls_are_unknown.show_unknowns

        expected_sql = <<~SQL.squish
                      SELECT "t".* FROM "t" WHERE "t"."test_bool" = TRUE
                      SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'handles clause false' do
        data = { clause: BooleanCondition::CLAUSE_FALSE }
        condition = BooleanCondition.new('test_bool').nulls_are_unknown.show_unknowns

        expected_sql = <<~SQL.squish
                      SELECT "t".* FROM "t" WHERE "t"."test_bool" = FALSE
                      SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'handles clause not set' do
        data = { clause: BooleanCondition::CLAUSE_NOT_SET }
        condition = BooleanCondition.new('test_bool').nulls_are_unknown.show_unknowns

        expected_sql = <<~SQL.squish
                        SELECT "t".* FROM "t" WHERE "t"."test_bool" IS NULL
                        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'handles clause set' do
        data = { clause: BooleanCondition::CLAUSE_SET }
        condition = BooleanCondition.new('test_bool').nulls_are_unknown.show_unknowns
        expected_sql = <<~SQL.squish
                        SELECT "t".* FROM "t" WHERE "t"."test_bool" IS NOT NULL
                        SQL

        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'handles true nulls' do
        data = { clause: BooleanCondition::CLAUSE_TRUE }
        condition = BooleanCondition.new('test_bool').nulls_are_true

        expected_sql = <<~SQL.squish
                        SELECT "t".* FROM "t" WHERE ("t"."test_bool" = TRUE OR "t"."test_bool" IS NULL)
                        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end

      it 'handles false nulls' do
        data = { clause: BooleanCondition::CLAUSE_FALSE }
        condition = BooleanCondition.new('test_bool').nulls_are_false
        expected_sql = <<~SQL.squish
                        SELECT "t".* FROM "t" WHERE ("t"."test_bool" = FALSE OR "t"."test_bool" IS NULL)
                        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
      end
    end
  end
end
