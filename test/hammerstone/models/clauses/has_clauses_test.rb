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
      skip
      condition = TextCondition.new('text_test')
      actual_clause = condition.to_array[:meta][:clauses]
      assert_equal text_condition_clauses, actual_clause
    end

    describe 'without clause' do
      it 'removes clause from configuration' do
        skip
        condition = TextCondition.new('text_test').without_clauses(TextCondition::CLAUSE_SET)
        actual_clause = condition.to_array[:meta][:clauses]
        assert_equal text_condition_clauses_without_set, actual_clause
      end
    end

    def text_condition_clauses
      [
        {
          :id=>"eq",
          :display=>"Equals",
          :meta=>{}
        },
        {
          :id=>"dne",
          :display=>"Does Not Equal",
          :meta=>{}
        },
        {
          :id=>"sw",
          :display=>"Starts With",
          :meta=>{}
        },
        {
          :id=>"ew",
          :display=>"Ends With",
          :meta=>{}
        },
        {
          :id=>"dsw",
          :display=>"Does Not Start With",
          :meta=>{}
        },
        {
          :id=>"dew",
          :display=>"Does Not End With",
          :meta=>{}
        },
        {
          :id=>"cont",
          :display=>"Contains",
          :meta=>{}
        },
        {
          :id=>"dcont",
          :display=>"Does Not Contain",
          :meta=>{}
        },
        {
          :id=>"st",
          :display=>"Is Set",
          :meta=>{}
        },
        {
          :id=>"nst",
          :display=>"Is Not Set",
          :meta=>{}
        }
      ]
    end

    def text_condition_clauses_without_set
      [
        {
          :id=>"eq",
          :display=>"Equals",
          :meta=>{}
        },
        {
          :id=>"dne",
          :display=>"Does Not Equal",
          :meta=>{}
        },
        {
          :id=>"sw",
          :display=>"Starts With",
          :meta=>{}
        },
        {
          :id=>"ew",
          :display=>"Ends With",
          :meta=>{}
        },
        {
          :id=>"dsw",
          :display=>"Does Not Start With",
          :meta=>{}
        },
        {
          :id=>"dew",
          :display=>"Does Not End With",
          :meta=>{}
        },
        {
          :id=>"cont",
          :display=>"Contains",
          :meta=>{}
        },
        {
          :id=>"dcont",
          :display=>"Does Not Contain",
          :meta=>{}
        },
        {
          :id=>"nst",
          :display=>"Is Not Set",
          :meta=>{}
        }
      ]
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