require "test_helper"
require 'support/test_filter'

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

  describe 'to array' do
    it 'has multiple conditions no meta' do
      filter = TestFilter.new([])
      expected_value =
      { type: "Hammerstone",
        blueprint: [],
        conditions: [{
                      id: "text_field_value",
                      component: 'text-condition',
                      display: "Text Field Value",
                      meta: ""
                   },{
                      id: "button_value",
                      component: 'text-condition',
                      display: "Button Value",
                      meta: ""
                   }],
        stable_id: 'dontcare'
      }
      assert_equal expected_value, filter.to_array
    end
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
