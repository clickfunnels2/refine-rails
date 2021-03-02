require "test_helper"

module Hammerstone::Refine::Conditions
  describe "Default Display" do
    it 'correctly displays string' do
      condition = BooleanCondition.new('test')
      assert_equal 'Test', condition.to_array[:display]
    end

    it 'correctly handles underscores' do
      condition = BooleanCondition.new('test_underscore')
      assert_equal 'Test Underscore', condition.to_array[:display]
    end

    it 'correctly handles set values' do
      condition = BooleanCondition.new('Explicitly Set')
      assert_equal 'Explicitly Set', condition.to_array[:display]
    end

    it 'can set display directly' do
      condition = BooleanCondition.new('test_underscore').with_display('Through Method')
      assert_equal 'Through Method', condition.to_array[:display]
    end

    it 'can set at the class level' do
      skip 'Revisit class level describe'
      test = Class.new(BooleanCondition)
      assert_equal 'Class Level', test.display
    end
  end
end