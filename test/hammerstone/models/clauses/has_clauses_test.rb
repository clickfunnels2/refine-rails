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

    describe 'configuration object to frontend' do

      it 'adds Clause to Meta' do
        condition = TextCondition.new('text_test')
        actual_clause = condition.to_array[:meta][:clauses]
        assert_equal text_condition_clauses, actual_clause
      end

      describe 'without single clause' do
        it 'removes clause from configuration' do
          condition = TextCondition.new('text_test').without_clauses([TextCondition::CLAUSE_SET])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal text_condition_clauses_without_set, actual_clause
        end
      end

      describe 'without multiple clauses' do
        it 'removes clauses from configuration' do
          condition = TextCondition.new('text_test').without_clauses([TextCondition::CLAUSE_SET, TextCondition::CLAUSE_EQUALS,TextCondition::CLAUSE_DOESNT_EQUAL ] )
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal text_condition_clauses_without_many.to_set, actual_clause.to_set
        end
      end

      describe 'only clauses' do
        it 'includes the correct clauses' do
          condition = TextCondition.new('text_test').only_clauses([TextCondition::CLAUSE_EQUALS])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal only_clauses, actual_clause
        end
      end

      describe 'with and only' do
        it 'can exclude from only' do
          condition = TextCondition.new('text_test')
            .only_clauses([TextCondition::CLAUSE_EQUALS, TextCondition::CLAUSE_SET])
            .without_clauses([TextCondition::CLAUSE_EQUALS])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal set_clause, actual_clause
        end
      end

      describe 'with and without' do
        it 'with adds condition back' do
          condition = TextCondition.new('text_test')
            .without_clauses([TextCondition::CLAUSE_EQUALS])
            .with_clauses([TextCondition::CLAUSE_EQUALS])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal text_condition_clauses, actual_clause
        end

        it 'without condition removes from with condition' do
          condition = TextCondition.new('text_test')
            .with_clauses([TextCondition::CLAUSE_EQUALS, TextCondition::CLAUSE_SET])
            .without_clauses([TextCondition::CLAUSE_SET])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal text_condition_clauses_without_set, actual_clause
        end
      end

      describe 'with and only' do
        it 'can add back after only' do
          condition = TextCondition.new('text_test')
            .only_clauses([TextCondition::CLAUSE_EQUALS])
            .with_clauses([TextCondition::CLAUSE_SET])
          actual_clause = condition.to_array[:meta][:clauses]
          assert_equal set_and_equal.to_set, actual_clause.to_set
        end
      end


    end

    def set_and_equal
      [
        {
          :id=>"st",
          :display=>"Is Set",
          :meta=>{}
        },
        {
          :id=>"eq",
          :display=>"Equals",
          :meta=>{}
        }
      ]
    end

    def set_clause
      [
        {
          :id=>"st",
          :display=>"Is Set",
          :meta=>{}
        }
      ]
    end

    def only_clauses
      [
        {
          :id=>"eq",
          :display=>"Equals",
          :meta=>{}
        }
      ]
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

    def text_condition_clauses_without_many
      [
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

  end
end