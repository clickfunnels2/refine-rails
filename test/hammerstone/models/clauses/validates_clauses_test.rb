require "test_helper"
require "support/hammerstone/filter_test_helper"

module Hammerstone::Refine::Conditions
  describe "Validates Clause" do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (text_test varchar(256));")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    describe "ensurance (developer side) validations" do
      it "fails if no id is given by the developer" do
        condition = ValidatesClausesTestCondition.new

        exception =
          assert_raises Hammerstone::Refine::Conditions::ConditionError do
            condition.to_array
          end
        assert_equal("[\"Every condition must have an ID\", \"An attribute is required.\"]", exception.message)
      end
    end

    it "fails with no clause id by raising error" do
      condition = ValidatesClausesTestCondition.new("text_test")
      user_input = {clause: "eq", value: "sample_value"}
      filter = apply_condition_and_return_filter(condition, user_input)
      assert_equal("0 [\"The clause with id eq was not found\"]", filter.errors.full_messages[0])
    end

    it "passes with clause id" do
      condition = ValidatesClausesTestCondition.new("text_test")
      user_input = {clause: "id_one", value: "sample_value"}
      condition.apply_condition_on_test_filter(condition, user_input)
      assert_equal condition.clauses[0].id, "id_one"
    end

    it "validates a clause exists (a clause is required)" do
      condition = ValidatesClausesTestCondition.new("text_test")
      user_input = {clause: nil}
      filter = apply_condition_and_return_filter(condition, user_input)
      assert_equal("0 [\"A clause is required for clause with id \"]", filter.errors.full_messages[0])
    end

    it "validates Text Condition Eq has a value" do
      condition = TextCondition.new("text_test") # Automatically have all the clauses with all the rules
      data = {clause: "eq", value: nil}
      filter = apply_condition_and_return_filter(condition, data)
      assert_equal("0 [\"A value is required for clause with id eq\"]", filter.errors.full_messages[0])
    end

    it "excludes clauses using without" do
      condition = ValidatesClausesTestCondition.new("text_test").without_clauses(["id_one"])
      data = {clause: "id_one", value: "foo"}
      filter = apply_condition_and_return_filter(condition, data)
      assert_equal("0 [\"The clause with id id_one was not found\"]", filter.errors.full_messages[0])
    end

    it "Returns condition and clause errors when multiple issues" do
      condition1 = ValidatesClausesTestCondition.new("text_test").without_clauses(["id_one"])
      condition2 = TextCondition.new("text_field_value")

      blueprint =
        [{
          "depth": 0,
          index: 0,
          "type": "criterion",
          "condition_id": "text_field_value",
          "input": {
            "clause": "eq",
            "value": nil
          }
        }, {
          "depth": 0,
          index: 1,
          "type": "conjunction",
          "word": "and"
        }, {
          "depth": 0,
          index: 2,
          "type": "criterion",
          "condition_id": "text_test",
          "input": {
            "clause": "id_one",
            "value": "aa"
          }
        }]

      filter = BlankTestFilter.new(blueprint,
        FilterTestHelper::TestDouble.all,
        [condition1, condition2],
        FilterTestHelper::TestDouble.arel_table)
      filter.get_query
      filter_errors = filter.errors.full_messages.map { |el| el.tr("\"", "`") }
      assert_equal(["0 [`A value is required for clause with id eq`]", "2 [`The clause with id id_one was not found`]"], filter_errors)
    end
  end

  class ValidatesClausesTestCondition < Condition
    include HasClauses
    include FilterTestHelper

    def apply_condition(query, input)
    end

    def clauses
      [
        Clause.new("id_one", "Display One"),
        Clause.new("id_two", "Display Two")
      ]
    end
  end
end
