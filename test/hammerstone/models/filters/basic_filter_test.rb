require "test_helper"
require 'support/test_filter'
require 'support/test_filter_with_meta'

describe Hammerstone::Refine::Filter do

  describe 'single basic condition' do
    it 'gets correct query' do
      query = TestFilter.new(single_condition_blueprint)
      correct_sql = "SELECT \"scaffolding_completely_concrete_tangible_things\".* FROM \"scaffolding_completely_concrete_tangible_things\" WHERE \"scaffolding_completely_concrete_tangible_things\".\"text_field_value\" = 'aaron'"
      assert_equal query.get_query.to_sql, correct_sql
    end
  end

  describe 'condition with wrong id' do
    it 'adds error' do
      query = TestFilter.new(bad_id)
      query.get_query
      assert query.errors.added? :filter, "The condition ID fake was not found"
    end
  end

  describe 'basic filters with ands' do
    it 'gets correct query' do
      query = TestFilter.new(and_condition_blueprint)
      assert_equal query.get_query.to_sql, and_sql
    end
  end

  describe 'To Array - data going to frontend' do

    describe 'Text Condition - no meta, no clauses' do
      it 'returns correct json' do
        filter = TestFilter.new([])
        expected_value =
        {
          type: "Hammerstone",
          blueprint: [],
          conditions: expected_conditions,
          stable_id: 'dontcare'
        }
        assert_equal expected_value, filter.to_array
      end
    end

    describe 'Text Condition with meta, no clauses' do
      it 'returns correct json' do
        skip "Meta nesting"
        filter = TestFilterWithMeta.new([])
        expected_value =
        {
          type: "Hammerstone",
          blueprint: [],
          conditions: expected_conditions_with_meta,
          stable_id: 'dontcare'
        }
        assert_equal expected_conditions_with_meta, filter.to_array
      end
    end
  end


  def expected_conditions_with_meta
    [
      {
        :id=>"text_field_value",
        :component=>"text-condition",
        :display=>"Text Field Value",
        :meta=>
          {
            :hint => "password",
            :clauses=>
              [
                {
                  :id=>"eq",
                  :display=>"Equals",
                  :meta=>[]
                },
                {
                  :id=>"dne",
                  :display=>"Does Not Equal",
                  :meta=>[]
                },
                {
                  :id=>"sw",
                  :display=>"Starts With",
                  :meta=>[]
                },
                {
                  :id=>"ew",
                  :display=>"Ends With",
                  :meta=>[]
                },
                {
                  :id=>"dsw",
                  :display=>"Does Not Start With",
                  :meta=>[]
                },
                {
                  :id=>"dew",
                  :display=>"Does Not End With",
                  :meta=>[]
                },
                {
                  :id=>"cont",
                  :display=>"Contains",
                  :meta=>[]
                },
                {
                  :id=>"dcont",
                  :display=>"Does Not Contain",
                  :meta=>[]
                },
                {
                  :id=>"st",
                  :display=>"Is Set",
                  :meta=>[]
                },
                {
                  :id=>"nst",
                  :display=>"Is Not Set",
                  :meta=>[]
                }
              ]
          },
      }
    ]
  end

  def expected_conditions
    [
      {
        :id=>"text_field_value",
        :component=>"text-condition",
        :display=>"Text Field Value",
        :meta=>
          {
            :clauses=>
              [
                {
                  :id=>"eq",
                  :display=>"Equals",
                  :meta=>nil
                },
                {
                  :id=>"dne",
                  :display=>"Does Not Equal",
                  :meta=>nil
                },
                {
                  :id=>"sw",
                  :display=>"Starts With",
                  :meta=>nil
                },
                {
                  :id=>"ew",
                  :display=>"Ends With",
                  :meta=>nil
                },
                {
                  :id=>"dsw",
                  :display=>"Does Not Start With",
                  :meta=>nil
                },
                {
                  :id=>"dew",
                  :display=>"Does Not End With",
                  :meta=>nil
                },
                {
                  :id=>"cont",
                  :display=>"Contains",
                  :meta=>nil
                },
                {
                  :id=>"dcont",
                  :display=>"Does Not Contain",
                  :meta=>nil
                },
                {
                  :id=>"st",
                  :display=>"Is Set",
                  :meta=>nil
                },
                {
                  :id=>"nst",
                  :display=>"Is Not Set",
                  :meta=>nil
                }
              ]
          },
      }
    ]
  end

  # ors do not work at this time
  # describe 'basic filters with ors' do
  #   it 'gets correct query' do
  #     query = TestFilter.new(or_condition_blueprint)
  #     assert_equal query.get_query.to_sql, or_sql
  #   end
  # end

  def and_sql
   "SELECT \"scaffolding_completely_concrete_tangible_things\".* FROM \"scaffolding_completely_concrete_tangible_things\" WHERE \"scaffolding_completely_concrete_tangible_things\".\"text_field_value\" = 'aaron' AND \"scaffolding_completely_concrete_tangible_things\".\"text_field_value\" = 'aa'"
  end

  def or_sql
     "SELECT \"scaffolding_completely_concrete_tangible_things\".* FROM \"scaffolding_completely_concrete_tangible_things\" WHERE (\"scaffolding_completely_concrete_tangible_things\".\"text_field_value\" = 'aaron' OR \"scaffolding_completely_concrete_tangible_things\".\"text_field_value\" = 'aa')"
  end

  # describe 'builder query' do
  #   #Works if blueprint doesn't have a type attribute
  #   it 'builds the query' do
  #     sql_query = "SELECT \"scaffolding_completely_concrete_tangible_things\".* FROM \"scaffolding_completely_concrete_tangible_things\" WHERE \"scaffolding_completely_concrete_tangible_things\".\"text_field_value\" = 'TextInATextField' AND \"scaffolding_completely_concrete_tangible_things\".\"button_value\" = 'one'"
  #     assert_equal subject.query.to_sql, sql_query
  #   end
  # end'

  def bad_id
    [{
      "depth": 0,
      "type": "criterion",
      "condition_id": "fake",
      "input": {
        "clause": "eq",
        "value": "aaron"
      }
    }]
  end

  def single_condition_blueprint
    [{
      "depth": 0,
      "type": "criterion",
      "condition_id": "text_field_value",
      "input": {
        "clause": "eq",
        "value": "aaron"
      }
    }]
  end

  def and_condition_blueprint
    [{ #criterion aaron and aa
      "depth": 0,
      "type": "criterion",
      "condition_id": "text_field_value",
      "input": {
        "clause": "eq",
        "value": "aaron"
      }
    }, { #conjunction
      "depth": 0,
      "type": "conjunction",
      "word": "and"
    }, { #criterion
      "depth": 0,
      "type": "criterion",
      "condition_id": "text_field_value",
      "input": {
        "clause": "eq",
        "value": "aa"
      }
    }]
  end

  def or_condition_blueprint
    [{ #criterion aaron OR aa
      "depth": 0,
      "type": "criterion",
      "condition_id": "text_field_value",
      "input": {
        "clause": "eq",
        "value": "aaron"
      }
    }, { #conjunction
      "depth": 0,
      "type": "conjunction",
      "word": "or"
    }, { #criterion
      "depth": 0,
      "type": "criterion",
      "condition_id": "text_field_value",
      "input": {
        "clause": "eq",
        "value": "aa"
      }
    }]
  end
end
