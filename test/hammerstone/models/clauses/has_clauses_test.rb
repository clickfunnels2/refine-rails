require "test_helper"
require 'support/filter_test_helper'

module Hammerstone::Refine::Conditions
  describe HasClauses do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (text_test varchar);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    it 'adds Clause to Meta' do
      condition = TextCondition.new('text_test')
      actual_clause = condition.to_array[:meta][:clauses]
      expected_clause = {
                          id: "eq",
                          display: "Equals",
                          meta: {},
                        }
      assert_equal expected_clause, actual_clause[0]
    end

    # class HasClausesTestCondition < Condition
    #   def clauses
    #     @clauses
    #   end
    #   def custom_clauses
    #     @custom_clauses
    #   end
    # end
  end
end