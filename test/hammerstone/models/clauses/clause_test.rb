require "test_helper"
require 'support/filter_test_helper'

module Hammerstone::Refine::Conditions
  describe Clause do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (text_test varchar);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    it 'add rule to clause with required input' do
      eq_clause = Clause.new('eq', 'Equals').requires_inputs('value')
      assert_equal eq_clause.rules, {value: 'required'}
    end

    it 'can add rules manually' do
      clause1 = Clause.new('clause1', 'Clause1').with_rules({ foo: 'required' })
      assert_equal clause1.rules, {foo: 'required'}
    end

    it 'can add rules later in lifecycle' do
      clause1 = Clause.new('clause1', 'Clause1').with_rules({ foo: 'required' })
      clause1.with_rules({ assignment: 'required' })
      assert_equal clause1.rules, { foo: 'required', assignment: 'required' }
    end
  end
end