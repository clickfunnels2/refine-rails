require "test_helper"
require "support/refine/test_double_filter"
require "refine/invalid_filter_error"

describe Refine::Filter do
  include FilterTestHelper

  around do |test|
    ApplicationRecord.connection.execute("CREATE TABLE t (test_bool boolean);")
    test.call
    ApplicationRecord.connection.execute("DROP TABLE t;")
  end

  describe "uses_or?" do
    it "returns false if the blueprint is nil" do
      query = create_filter
      assert_equal query.uses_or?, false
    end

    it "returns false if the blueprint is empty" do
      query = create_filter([])
      assert_equal query.uses_or?, false
    end

    it "returns false for a single condition blueprint" do
      query = create_filter(single_condition_blueprint)
      assert_equal query.uses_or?, false
    end

    it "returns false for a mutli-condition blueprint of only ANDs" do
      query = create_filter(and_condition_blueprint)
      assert_equal query.uses_or?, false
    end

    it "returns true for a multi-condition blueprint with an OR" do
      query = create_filter(or_condition_blueprint)
      assert_equal query.uses_or?, true
    end

    it "returns true for a multi-condition AND and OR blueprint" do
      query = create_filter(grouped_or_blueprint)
      assert_equal query.uses_or?, true
    end
  end

  describe "uses_and?" do
    it "returns false if the blueprint is nil" do
      query = create_filter
      assert_equal query.uses_and?, false
    end

    it "returns false if the blueprint is empty" do
      query = create_filter([])
      assert_equal query.uses_and?, false
    end

    it "returns false for a single condition blueprint" do
      query = create_filter(single_condition_blueprint)
      assert_equal query.uses_and?, false
    end

    it "returns true for a mutli-condition blueprint of only ANDs" do
      query = create_filter(and_condition_blueprint)
      assert_equal query.uses_and?, true
    end

    it "returns false for a multi-condition blueprint with an OR" do
      query = create_filter(or_condition_blueprint)
      assert_equal query.uses_and?, false
    end

    it "returns true for a multi-condition AND and OR blueprint" do
      query = create_filter(grouped_or_blueprint)
      assert_equal query.uses_and?, true
    end
  end

  describe "uses_condition" do
    it "returns false if the blueprint is nil" do
      query = create_filter
      assert_equal query.uses_condition("text_field_value"), false
    end

    it "returns false if the blueprint is empty" do
      query = create_filter([])
      assert_equal query.uses_condition("text_field_value"), false
    end

    it "returns true if the condition is in use in the blueprint" do
      query = create_filter(single_condition_blueprint)
      assert_equal query.uses_condition("text_field_value"), true
    end

    it "returns false if the condition is not in use in the blueprint" do
      query = create_filter(single_condition_blueprint)
      assert_equal query.uses_condition("fake"), false
    end

    it "returns true if the condition is in use in the blueprint with the supplied clause" do
      query = create_filter(single_condition_blueprint)
      assert_equal query.uses_condition("text_field_value", using_clauses: "eq"), true
    end
    
    it "returns true if the condition is in use in the blueprint with one of the included clauses" do
      query = create_filter(single_condition_blueprint)
      assert_equal query.uses_condition("text_field_value", using_clauses: ["eq", "cont"]), true
    end

    it "returns false if the condition is in use in the blueprint without the clause" do
      query = create_filter(single_condition_blueprint)
      assert_equal query.uses_condition("text_field_value", using_clauses: "cont"), false
    end

    it "returns false if the condition is in use in the blueprint without one of the included clauses" do
      query = create_filter(single_condition_blueprint)
      assert_equal query.uses_condition("text_field_value", using_clauses: ["cont", "gt"]), false
    end
  end

  describe "uses_negative_clause?" do
    it "returns false if the blueprint is nil" do
      query = create_filter
      assert_equal query.uses_negative_clause?, false
    end

    it "returns false if the blueprint is empty" do
      query = create_filter([])
      assert_equal query.uses_negative_clause?, false
    end

    it "returns true if the blueprint contains a negative clause" do
      query = create_filter(single_condition_blueprint)
      assert_equal query.uses_negative_clause?, false
    end

    it "returns false if the blueprint does not contain a negative clause" do
      query = create_filter(invalid_condition_blueprint)
      assert_equal query.uses_negative_clause?, false
    end

    it "returns true if the blueprint contains a negative clause" do
      query = create_filter(grouped_or_blueprint_negative)
      assert_equal query.uses_negative_clause?, true
    end
  end

  def grouped_blueprint
    Refine::Blueprints::Blueprint.new
      .criterion("text_field_value",
        clause: Refine::Conditions::TextCondition::CLAUSE_EQUALS,
        value: "one",)
      .and
      .group {
        criterion("text_field_value",
          clause: Refine::Conditions::TextCondition::CLAUSE_EQUALS,
          value: "two",)
          .and
          .criterion("text_field_value",
            clause: Refine::Conditions::TextCondition::CLAUSE_EQUALS,
            value: "three",)
      }
  end

  def nested_group_blueprint
    Refine::Blueprints::Blueprint.new
      .criterion("text_field_value",
        clause: Refine::Conditions::TextCondition::CLAUSE_EQUALS,
        value: "one",)
      .and
      .group {
        group {
          criterion("text_field_value",
            clause: Refine::Conditions::TextCondition::CLAUSE_EQUALS,
            value: "two",)
            .and
            .criterion("text_field_value",
              clause: Refine::Conditions::TextCondition::CLAUSE_EQUALS,
              value: "three",)
        }
          .and
          .criterion("text_field_value",
            clause: Refine::Conditions::TextCondition::CLAUSE_EQUALS,
            value: "four",)
      }
      .and
      .criterion("text_field_value",
        clause: Refine::Conditions::TextCondition::CLAUSE_EQUALS,
        value: "five")
  end

  def create_filter(blueprint=nil)
    BlankTestFilter.new(blueprint,
      FilterTestHelper::TestDouble.all,
      [Refine::Conditions::TextCondition.new("text_field_value")],
      FilterTestHelper::TestDouble.arel_table)
  end


  def bad_id
    [{
      depth: 0,
      type: "criterion",
      condition_id: "fake",
      input: {
        clause: "eq",
        value: "aaron"
      }
    }]
  end

  def single_condition_blueprint
    [{
      depth: 0,
      type: "criterion",
      condition_id: "text_field_value",
      input: {
        clause: "eq",
        value: "aaron"
      }
    }]
  end

  def invalid_condition_blueprint
    [{
      depth: 0,
      type: "criterion",
      condition_id: "invalid_condition",
      input: {
        clause: "eq",
        value: "invalid"
      }
    }]
  end

  def and_condition_blueprint
    [{ # criterion aaron and aa
      depth: 0,
      type: "criterion",
      condition_id: "text_field_value",
      input: {
        clause: "eq",
        value: "aaron"
      }
    }, { # conjunction
      depth: 0,
      type: "conjunction",
      word: "and"
    }, { # criterion
      depth: 0,
      type: "criterion",
      condition_id: "text_field_value",
      input: {
        clause: "eq",
        value: "aa"
      }
    }]
  end

  def or_condition_blueprint
    [{ # criterion aaron OR aa
      depth: 0,
      type: "criterion",
      condition_id: "text_field_value",
      input: {
        clause: "eq",
        value: "aaron"
      }
    }, { # conjunction
      depth: 0,
      type: "conjunction",
      word: "or"
    }, { # criterion
      depth: 0,
      type: "criterion",
      condition_id: "text_field_value",
      input: {
        clause: "eq",
        value: "aa"
      }
    }]
  end

  def grouped_or_blueprint
    [{
      type: "criterion",
      condition_id: "user_name",
      depth: 1,
      input: {
        clause: "cont",
        value: "Aaron"
      }
    },
      {
        type: "conjunction",
        word: "and",
        depth: 1
      },
      {
        type: "criterion",
        condition_id: "user_name",
        depth: 1,
        input: {
          clause: "cont",
          value: "Francis"
        }
      },
      {
        type: "conjunction",
        word: "or",
        depth: 0
      },
      {
        type: "criterion",
        condition_id: "user_name",
        depth: 1,
        input: {
          clause: "cont",
          value: "Sean"
        }
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1
      },
      {
        type: "criterion",
        condition_id: "user_name",
        depth: 1,
        input: {
          clause: "cont",
          value: "Fioritto"
        }
      }]
  end

  def grouped_or_blueprint_negative
    [{
      type: "criterion",
      condition_id: "user_name",
      depth: 1,
      input: {
        clause: "cont",
        value: "Aaron"
      }
    },
      {
        type: "conjunction",
        word: "and",
        depth: 1
      },
      {
        type: "criterion",
        condition_id: "user_name",
        depth: 1,
        input: {
          clause: "dcont",
          value: "Francis"
        }
      },
      {
        type: "conjunction",
        word: "or",
        depth: 0
      },
      {
        type: "criterion",
        condition_id: "user_name",
        depth: 1,
        input: {
          clause: "cont",
          value: "Sean"
        }
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1
      },
      {
        type: "criterion",
        condition_id: "user_name",
        depth: 1,
        input: {
          clause: "cont",
          value: "Fioritto"
        }
      }]
  end
end
