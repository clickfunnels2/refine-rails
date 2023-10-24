require "test_helper"
require "support/refine/filter_test_helper"

module Refine::Conditions
  describe "NumericConditionZero" do
    include FilterTestHelper

    let(:condition) { NumericCondition.new("numeric_test") }

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (numeric_test integer, numeric_float decimal);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    it "clause equals and 0" do
      input = {clause: NumericCondition::CLAUSE_EQUALS, value1: 0}
      assert_equal(condition.input_could_include_zero?(input), true)
    end

    it "clause equals and 1" do
      input = {clause: NumericCondition::CLAUSE_EQUALS, value1: 1}
      assert_equal(condition.input_could_include_zero?(input), false)
    end

    it "clause equals and -1" do
      input = {clause: NumericCondition::CLAUSE_EQUALS, value1: -1}
      assert_equal(condition.input_could_include_zero?(input), false)
    end

    it "clause doesn't equal and 0" do
      input = {clause: NumericCondition::CLAUSE_DOESNT_EQUAL, value1: 0}
      assert_equal(condition.input_could_include_zero?(input), false)
    end

    it "clause doesn't equal and 1" do
      input = {clause: NumericCondition::CLAUSE_DOESNT_EQUAL, value1: 1}
      assert_equal(condition.input_could_include_zero?(input), true)
    end

    it "clause less than or equal and 0" do
      input = {clause: NumericCondition::CLAUSE_LESS_THAN_OR_EQUAL, value1: 0}
      assert_equal(condition.input_could_include_zero?(input), true)
    end

    it "clause less than or equal and 1" do
      input = {clause: NumericCondition::CLAUSE_LESS_THAN_OR_EQUAL, value1: 1}
      assert_equal(condition.input_could_include_zero?(input), true)
    end

    it "clause less than or equal and -1" do
      input = {clause: NumericCondition::CLAUSE_LESS_THAN_OR_EQUAL, value1: -1}
      assert_equal(condition.input_could_include_zero?(input), false)
    end
  end
end
