require "test_helper"
require "support/refine/blank_test_filter"
require "support/refine/test_double_filter"
# Note - this test uses the tangible things locale file currently. TODO make this more reusable

module Refine::Conditions
  describe "Default Display no locales file" do
    before do
      @filter = BlankTestFilter.new([])
    end

    it "correctly displays string" do
      condition = BooleanCondition.new("test")
      @filter.conditions = [condition]
      @filter.conditions_to_array
      assert_equal "Test", condition.to_array[:display]
    end

    it "correctly handles underscores" do
      condition = BooleanCondition.new("test_underscore")
      @filter.conditions = [condition]
      @filter.conditions_to_array
      assert_equal "Test Underscore", condition.to_array[:display]
    end

    it "correctly handles set values" do
      condition = BooleanCondition.new("Explicitly Set")
      @filter.conditions = [condition]
      @filter.conditions_to_array
      assert_equal "Explicitly Set", condition.to_array[:display]
    end

    it "can set display directly" do
      condition = BooleanCondition.new("test_underscore").with_display("Through Method")
      @filter.conditions = [condition]
      @filter.conditions_to_array
      assert_equal "Through Method", condition.to_array[:display]
    end

    it "can set at the class level" do
      skip "Revisit class level describe"
      test = Class.new(BooleanCondition)
      assert_equal "Class Level", test.display
    end
  end

  describe "Display with locales file" do
    before do
      # Test filter is defined to use the tangible things locale file
      @filter = TestDoubleFilter.new(["random id"])
    end

    it "correctly translates string when locales file present" do
      skip "Create test local file"
      condition = BooleanCondition.new("automation_emails")
      @filter.conditions = [condition]
      @filter.conditions_to_array
      assert_equal "Emails that are automated", condition.to_array[:display]
    end

    it "uses human readable id when id is not in local file" do
      condition = BooleanCondition.new("use_default")
      @filter.conditions = [condition]
      @filter.conditions_to_array
      assert_equal "Use Default", condition.to_array[:display]
    end
  end
end
