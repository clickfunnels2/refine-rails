require "test_helper"
require 'support/filter_test_helper'

module Hammerstone::Refine::Conditions
  describe 'User Meta on Conditions' do
    it 'deconstructs meta single level' do
      user_meta = { foo: 'bar', other_stuff: Proc.new{'For the frontend'} }
      expected_value = { foo: 'bar', other_stuff: 'For the frontend' }

      condition = BooleanCondition.new('boolean_test').with_meta(user_meta)
      #Strip clauses out of meta array
      assert_equal condition.meta.without(:clauses), user_meta
      assert_equal expected_value, condition.recursively_evaluate_lazy_array(user_meta)
    end

    it 'can add meta later in lifecycle' do
      user_meta = { hint: 'password' }
      condition = BooleanCondition.new('boolean_test').with_meta(user_meta)
      condition.with_meta( {other_meta: 'something_else'} )

      expected_value = { hint: 'password', other_meta: 'something_else' }
      assert_equal expected_value,  condition.meta.without(:clauses)
    end
  end
end