require "test_helper"

describe Hammerstone::Refine::Blueprints::Blueprint do
  describe "single basic condition" do
    it "creates blueprint" do
      builder = Hammerstone::Refine::Blueprints::Blueprint.new.criterion("id",
        clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
        value1: "foo",)
      assert_equal single_condition_blueprint, builder.to_array
    end
  end

  describe "basic filter with ands" do
    it "creates blueprint" do
      builder = Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("id",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
          value1: "fun",)
        .and
        .criterion("id",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
          value1: "inthesun",)
      assert_equal and_condition_blueprint, builder.to_array
    end
  end

  describe "basic filter with ors" do
    it "creates blueprint" do
      builder = Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("id",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
          value1: "dogs",)
        .or
        .criterion("id",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
          value1: "cats",)
      assert_equal builder.to_array, or_condition_blueprint
    end
  end

  describe "basic filter with groups" do
    it "creates blueprint" do
      builder = Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("id",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
          value1: "one",)
        .and
        .group {
        criterion("id",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
          value1: "two",)
          .and
          .criterion("id",
            clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
            value1: "three",)
      }
      assert_equal filter_with_groups_blueprint, builder.to_array
    end
  end

  describe "basic filter with nested groups" do
    it "creates blueprint" do
      builder = Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("id",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
          value: "one",)
        .and
        .group {
        group {
          criterion("id",
            clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
            value: "two",)
            .and
            .criterion("id",
              clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
              value: "three",)
        }
          .and
          .criterion("id",
            clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
            value: "four",)
      }
        .and
        .criterion("id",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
          value: "five")
      assert_equal nested_condition_blueprint, builder.to_array
    end
  end

  def nested_condition_blueprint
    [
      {
        type: "criterion",
        condition_id: "id",
        depth: 0,
        input: {
          clause: "eq",
          value: "one",
        },
      },
      {
        type: "conjunction",
        word: "and",
        depth: 0,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 2,
        input: {
          clause: "eq",
          value: "two",
        },
      },
      {
        type: "conjunction",
        word: "and",
        depth: 2,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 2,
        input: {
          clause: "eq",
          value: "three",
        },
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "four",
        },
      },
      {
        type: "conjunction",
        word: "and",
        depth: 0,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 0,
        input: {
          clause: "eq",
          value: "five",
        },
      }
    ]
  end

  def filter_with_groups_blueprint
    [
      {
        type: "criterion",
        condition_id: "id",
        depth: 0,
        input: {
          clause: "eq",
          value1: "one",
        },
      },
      {
        type: "conjunction",
        word: "and",
        depth: 0,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value1: "two"
        }
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value1: "three"
        }
      }
    ]
  end

  def single_condition_blueprint
    [
      {
        depth: 0,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value1: "foo"
        }
      }
    ]
  end

  def and_condition_blueprint
    [
      {
        depth: 0,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value1: "fun"
        }
      },
      { # conjunction
        depth: 0,
        type: "conjunction",
        word: "and"
      },
      { # criterion
        depth: 0,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value1: "inthesun"
        }
      }
    ]
  end

  def or_condition_blueprint
    [
      {
        depth: 0,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value1: "dogs"
        }
      },
      { # conjunction
        depth: 0,
        type: "conjunction",
        word: "or"
      },
      { # criterion
        depth: 0,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value1: "cats"
        }
      }
    ]
  end
end
