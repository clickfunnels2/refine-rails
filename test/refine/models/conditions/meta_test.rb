require "test_helper"
require "support/refine/filter_test_helper"

module Refine::Conditions
  describe "User Meta on Conditions" do
    it "deconstructs meta single level" do
      user_meta = {foo: "bar", other_stuff: proc { "For the frontend" }}
      expected_value = {foo: "bar", other_stuff: "For the frontend"}

      condition = BooleanCondition.new("boolean_test").with_meta(user_meta)
      # Strip clauses out of meta array
      assert_equal condition.meta.without(:clauses), user_meta
      assert_equal expected_value, condition.recursively_evaluate_lazy_enumerable(user_meta)
    end

    it "handles nested procs" do
      meta = {
        options:
          [
            {
              id: "ID1",
              display: "Display1",
              value: proc { "A mysterious value" },
            }
          ]
      }
      condition = BooleanCondition.new("boolean_test").with_meta(meta)
      assert_equal nested_expected_value, condition.recursively_evaluate_lazy_enumerable(meta)
    end

    it "can add meta later in lifecycle" do
      user_meta = {hint: "password"}
      condition = BooleanCondition.new("boolean_test").with_meta(user_meta)
      condition.with_meta({other_meta: "something_else"})

      expected_value = {hint: "password", other_meta: "something_else"}

      assert_equal expected_value, condition.meta.without(:clauses)
    end

    def nested_expected_value
      {
        options:
          [
            {
              id: "ID1",
              display: "Display1",
              value: "A mysterious value"
            }
          ]
      }
    end
  end
end
