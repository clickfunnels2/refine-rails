require "test_helper"
require 'support/filter_test_helper'

module Hammerstone::Refine::Conditions
  describe 'Validates Clause' do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (text_test varchar);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    describe 'ensurance (developer side) validations' do
      it 'fails if no id is given by the developer' do
        condition = ValidatesClausesTestCondition.new
        user_input = { clause: 'eq', value: 'sample_value'}

        exception =
          assert_raises Hammerstone::Refine::Conditions::ConditionError do
            condition.to_array
          end
        assert_equal("[\"Every condition must have an ID\", \"An attribute is required.\"]", exception.message)

      end
    end

    it 'fails with no clause id by raising error' do
      condition = ValidatesClausesTestCondition.new('text_test')
      user_input = { clause: 'eq', value: 'sample_value'}

      exception =
        assert_raises Hammerstone::Refine::Conditions::Errors::ConditionClauseError do
          condition.apply_condition_on_test_filter(condition, user_input)
        end
      assert_equal("[\"The clause with id eq was not found\"]", exception.message)

    end

    it 'passes with clause id' do
      condition = ValidatesClausesTestCondition.new('text_test')
      user_input = { clause: 'id_one', value: 'sample_value'}
      condition.apply_condition_on_test_filter(condition, user_input)
      assert_equal condition.clauses[0].id, 'id_one'
    end

    it 'validates a clause exists (a clause is required)' do
      condition = ValidatesClausesTestCondition.new('text_test')
      user_input = { clause: nil }
      exception =
        assert_raises Hammerstone::Refine::Conditions::Errors::ConditionClauseError do
          condition.apply_condition_on_test_filter(condition, user_input)
        end
      assert_equal("[\"A clause is required for clause with id \"]", exception.message)
    end

    it 'validates Text Condition Eq has a value' do
      condition = TextCondition.new('text_test') #Should automatically have all the clauses with all the rules
      data = { clause: 'eq', value: nil }
      exception = assert_raises Hammerstone::Refine::Conditions::Errors::ConditionClauseError do
        apply_condition_on_test_filter(condition, data)
      end
      assert_equal("[\"A value is required for clause with id eq\"]", exception.message)
    end

    it 'excludes clauses using without' do
      condition = ValidatesClausesTestCondition.new('text_test').without_clauses(['id_one'])
      data = { clause: 'id_one', value: 'foo' }
      exception = assert_raises Hammerstone::Refine::Conditions::Errors::ConditionClauseError do
        apply_condition_on_test_filter(condition, data)
      end
      assert_equal("[\"The clause with id id_one was not found\"]", exception.message)
    end
  end

  class ValidatesClausesTestCondition < Condition
    include HasClauses
    include FilterTestHelper

    def apply_condition(query, input)
    end

    def clauses
      [
        Clause.new('id_one', 'Display One'),
        Clause.new('id_two', 'Display Two')
      ]
    end
  end
end

