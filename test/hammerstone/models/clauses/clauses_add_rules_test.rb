require "test_helper"
require "support/hammerstone/filter_test_helper"

module Hammerstone::Refine::Conditions
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
      assert_equal("0 [\"A foo is required for clause with id clause_1\"]", filter.errors.full_messages[0])
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
