require "test_helper"
require 'support/filter_test_helper'

module Hammerstone::Refine::Conditions
  describe NumericCondition do
    include FilterTestHelper

    let(:condition) { NumericCondition.new('numeric_test') }

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (numeric_test decimal);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    it 'handles clause EQUALS' do
      skip 'integer or decimal value?'
      data = { clause: NumericCondition::CLAUSE_EQUALS, value1: 5 }

      expected_sql = <<~SQL.squish
                    SELECT "t".* FROM "t" WHERE "t"."numeric_test" = 5
                    SQL
      assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
    end

    it 'handles clause GREATER THAN' do
      data = { clause: NumericCondition::CLAUSE_GREATER_THAN, value1: 5 }

      expected_sql = <<~SQL.squish
                    SELECT "t".* FROM "t" WHERE (numeric_test > 5)
                    SQL
      assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
    end

    it 'handles clause GREATER THAN OR EQUAL' do
      data = { clause: NumericCondition::CLAUSE_GREATER_THAN_OR_EQUAL, value1: 5 }

      expected_sql = <<~SQL.squish
                    SELECT "t".* FROM "t" WHERE (numeric_test >= 5)
                    SQL
      assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
    end

    it 'handles clause LESS THAN' do
      data = { clause: NumericCondition::CLAUSE_LESS_THAN, value1: 5 }

      expected_sql = <<~SQL.squish
                    SELECT "t".* FROM "t" WHERE (numeric_test < 5)
                    SQL
      assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
    end

    it 'handles clause LESS THAN OR EQUAL' do
      data = { clause: NumericCondition::CLAUSE_LESS_THAN_OR_EQUAL, value1: 5 }

      expected_sql = <<~SQL.squish
                    SELECT "t".* FROM "t" WHERE (numeric_test <= 5)
                    SQL
      assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
    end

    it 'handles clause CLAUSE BETWEEN' do
      skip 'TODO finish numeric conditions'
      data = { clause: NumericCondition::CLAUSE_BETWEEN, value1: 5 }

      expected_sql = <<~SQL.squish

                    SQL
      assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
    end
    it 'handles clause CLAUSE SET' do
      skip 'TODO finish numeric conditions'
      data = { clause: NumericCondition::CLAUSE_SET, value1: 5 }

      expected_sql = <<~SQL.squish

                    SQL
      assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
    end

    it 'handles clause CLAUSE NOT SET' do
      skip 'TODO finish numeric conditions'
      data = { clause: NumericCondition::CLAUSE_NOT_SET, value1: 5 }

      expected_sql = <<~SQL.squish

                    SQL
      assert_equal expected_sql, apply_condition_on_test_filter(condition, data).to_sql
    end
  end
end
