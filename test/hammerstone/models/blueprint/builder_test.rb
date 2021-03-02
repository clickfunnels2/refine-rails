require "test_helper"

describe Hammerstone::Refine::Blueprints::Blueprint do

  describe 'single basic condition' do
    it 'creates blueprint' do
      builder = Hammerstone::Refine::Blueprints::Blueprint.new.criterion('id',
                clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
                value1: 'foo',
                )
      assert_equal builder.to_array, single_condition_blueprint
    end
  end

  describe 'basic filter with ands' do
    it 'creates blueprint' do
      builder = Hammerstone::Refine::Blueprints::Blueprint.new
                .criterion('id',
                  clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
                  value1: 'fun',
                )
                .and
                .criterion('id',
                  clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
                  value1: 'inthesun',
                )
      assert_equal builder.to_array, and_condition_blueprint
    end
  end

  describe 'basic filter with ors' do
    it 'creates blueprint' do
      builder = Hammerstone::Refine::Blueprints::Blueprint.new
                .criterion('id',
                  clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
                  value1: 'dogs',
                )
                .or
                .criterion('id',
                  clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
                  value1: 'cats',
                )
      assert_equal builder.to_array, or_condition_blueprint
    end
  end

  def single_condition_blueprint
    [
      {
        "depth": 0,
        "type": "criterion",
        "condition_id": "id",
        "input": {
          "clause": "eq",
          "value1": "foo"
        }
      }
    ]
  end

  def and_condition_blueprint
    [
      {
      "depth": 0,
      "type": "criterion",
      "condition_id": "id",
      "input": {
        "clause": "eq",
        "value1": "fun"
      }
      },
      { #conjunction
        "depth": 0,
        "type": "conjunction",
        "word": "and"
      },
      { #criterion
        "depth": 0,
        "type": "criterion",
        "condition_id": "id",
        "input": {
          "clause": "eq",
          "value1": "inthesun"
        }
      }
    ]
  end

  def or_condition_blueprint
    [
      {
      "depth": 0,
      "type": "criterion",
      "condition_id": "id",
      "input": {
        "clause": "eq",
        "value1": "dogs"
      }
      },
      { #conjunction
        "depth": 0,
        "type": "conjunction",
        "word": "or"
      },
      { #criterion
        "depth": 0,
        "type": "criterion",
        "condition_id": "id",
        "input": {
          "clause": "eq",
          "value1": "cats"
        }
      }
    ]
  end
end
