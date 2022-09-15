require "test_helper"
require "support/hammerstone/filter_test_helper"

module Hammerstone::Refine::Conditions
  describe HasClauses do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (text_test varchar(256));")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    describe "configuration object to frontend" do
      it "adds Clause to Meta" do
        condition = TextCondition.new("text_test")
        actual_clause = condition.to_array[:meta][:clauses]
        assert_equal text_condition_clauses, actual_clause
      end

      describe "without single clause" do
        it "removes clause from configuration" do
          condition = TextCondition.new("text_test").without_clauses([TextCondition::CLAUSE_SET])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal text_condition_clauses_without_set, actual_clause
        end
      end

      describe "without multiple clauses" do
        it "removes clauses from configuration" do
          condition = TextCondition.new("text_test").without_clauses([TextCondition::CLAUSE_SET, TextCondition::CLAUSE_EQUALS, TextCondition::CLAUSE_DOESNT_EQUAL])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal text_condition_clauses_without_many.to_set, actual_clause.to_set
        end
      end

      describe "only clauses" do
        it "includes the correct clauses" do
          condition = TextCondition.new("text_test").only_clauses([TextCondition::CLAUSE_EQUALS])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal only_clauses, actual_clause
        end
      end

      describe "with and only" do
        it "can exclude from only" do
          condition = TextCondition.new("text_test")
            .only_clauses([TextCondition::CLAUSE_EQUALS, TextCondition::CLAUSE_SET])
            .without_clauses([TextCondition::CLAUSE_EQUALS])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal set_clause, actual_clause
        end
      end

      describe "with and without" do
        it "with adds condition back" do
          condition = TextCondition.new("text_test")
            .without_clauses([TextCondition::CLAUSE_EQUALS])
            .with_clauses([TextCondition::CLAUSE_EQUALS])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal text_condition_clauses, actual_clause
        end

        it "without condition removes from with condition" do
          condition = TextCondition.new("text_test")
            .with_clauses([TextCondition::CLAUSE_EQUALS, TextCondition::CLAUSE_SET])
            .without_clauses([TextCondition::CLAUSE_SET])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal text_condition_clauses_without_set, actual_clause
        end
      end

      describe "with and only" do
        it "can add back after only" do
          condition = TextCondition.new("text_test")
            .only_clauses([TextCondition::CLAUSE_EQUALS])
            .with_clauses([TextCondition::CLAUSE_SET])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal set_and_equal.to_set, actual_clause.to_set
        end
      end
    end

    describe "clause ensurances" do
      it "must have a display - nil is overriden with humanized id" do
        condition = HasClausesTestCondition.new("text_test")
        condition.clauses = ([Clause.new("id", nil)])
        actual_clause_display = condition.to_array[:meta][:clauses][0][:display]
        assert_equal "Id", actual_clause_display
      end
    end

    def set_and_equal
      [
        {
          id: "st",
          display: "is set",
          meta: {}
        },
        {
          id: "eq",
          display: "is",
          meta: {}
        }
      ]
    end

    def set_clause
      [
        {
          id: "st",
          display: "is set",
          meta: {}
        }
      ]
    end

    def only_clauses
      [
        {
          id: "eq",
          display: "is",
          meta: {}
        }
      ]
    end

    def text_condition_clauses
      [
        {
          id: "eq",
          display: "is",
          meta: {}
        },
        {
          id: "dne",
          display: "is not",
          meta: {}
        },
        {
          id: "sw",
          display: "starts with",
          meta: {}
        },
        {
          id: "ew",
          display: "ends with",
          meta: {}
        },
        {
          id: "dsw",
          display: "does not start with",
          meta: {}
        },
        {
          id: "dew",
          display: "does not end with",
          meta: {}
        },
        {
          id: "cont",
          display: "contains",
          meta: {}
        },
        {
          id: "dcont",
          display: "does not contain",
          meta: {}
        },
        {
          id: "st",
          display: "is set",
          meta: {}
        },
        {
          id: "nst",
          display: "is not set",
          meta: {}
        }
      ]
    end

    def text_condition_clauses_without_many
      [
        {
          id: "sw",
          display: "starts with",
          meta: {}
        },
        {
          id: "ew",
          display: "ends with",
          meta: {}
        },
        {
          id: "dsw",
          display: "does not start with",
          meta: {}
        },
        {
          id: "dew",
          display: "does not end with",
          meta: {}
        },
        {
          id: "cont",
          display: "contains",
          meta: {}
        },
        {
          id: "dcont",
          display: "does not contain",
          meta: {}
        },
        {
          id: "nst",
          display: "is not set",
          meta: {}
        }
      ]
    end

    def text_condition_clauses_without_set
      [
        {
          id: "eq",
          display: "is",
          meta: {}
        },
        {
          id: "dne",
          display: "is not",
          meta: {}
        },
        {
          id: "sw",
          display: "starts with",
          meta: {}
        },
        {
          id: "ew",
          display: "ends with",
          meta: {}
        },
        {
          id: "dsw",
          display: "does not start with",
          meta: {}
        },
        {
          id: "dew",
          display: "does not end with",
          meta: {}
        },
        {
          id: "cont",
          display: "contains",
          meta: {}
        },
        {
          id: "dcont",
          display: "does not contain",
          meta: {}
        },
        {
          id: "nst",
          display: "is not set",
          meta: {}
        }
      ]
    end
  end

  class HasClausesTestCondition < Condition
    attr_accessor :clauses

    def component
    end
  end
end
