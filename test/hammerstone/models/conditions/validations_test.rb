require "test_helper"

module Hammerstone::Refine::Conditions
  describe "Basic Condition Validations" do
    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (test_bool boolean);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    # it 'sets id' do
    #   condition = BooleanCondition.new('boolean_test')
    #   assert_equal condition.id, 'boolean_test'
    # end

    it "raises an error if no id is set on the way to front end" do
      condition = BooleanCondition.new.with_attribute("Attribute")

      exception =
        assert_raises Hammerstone::Refine::Conditions::ConditionError do
          condition.to_array
        end
      assert_equal("[\"Every condition must have an ID\"]", exception.message)
    end

    it "raises an error if no id and no attribute" do
      condition = BooleanCondition.new

      exception =
        assert_raises Hammerstone::Refine::Conditions::ConditionError do
          condition.to_array
        end
      assert_equal("[\"Every condition must have an ID\", \"An attribute is required.\"]", exception.message)
    end
  end
end
