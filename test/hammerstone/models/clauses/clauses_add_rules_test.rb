require "test_helper"
require 'support/filter_test_helper'

module Hammerstone::Refine::Conditions
  describe 'Clauses Add Rules' do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (text_test varchar);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    it 'a clause can add rules that are enforced' do
      condition = ClausesAddRulesTestCondition.new('test')

      user_input = { clause: 'clause_1', value: 'sample_value'}

      exception =
        assert_raises Hammerstone::Refine::Conditions::Errors::ConditionClauseError do
          condition.apply_condition_on_test_filter(condition, user_input)
          #condition.apply(FilterTestHelper::TestDouble.all, user_input)
        end
      assert_equal("[\"A foo is required for clause with id clause_1\"]", exception.message)
    end
  end

  class ClausesAddRulesTestCondition < Condition
    include HasClauses
    include FilterTestHelper

    def with_clauses(value)
      @clauses = value
    end

    def clauses
      [
        Clause.new('clause_1', 'Clause1').with_rules({ foo: 'required' })
      ]
    end

    def applyCondition(query, input)
    end

  end
end