require "test_helper"
require "support/refine/filter_test_helper"

module Refine::Conditions
  describe "Clauses Add Rules" do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (text_test varchar(256));")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    it "a clause can add rules that are enforced" do
      condition = ClausesAddRulesTestCondition.new("test")

      user_input = {clause: "clause_1", value: "sample_value"}

      filter = apply_condition_and_return_filter(condition, user_input)
      assert_equal(["A foo is required"], filter.errors.full_messages)
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
        Clause.new("clause_1", "Clause1").with_rules({foo: "required"})
      ]
    end

    def applyCondition(query, input)
    end
  end
end
