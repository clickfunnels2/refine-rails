require "test_helper"
require "support/hammerstone/test_double_filter"
require "hammerstone/refine/invalid_filter_error"

describe Hammerstone::Refine::Filter do
  include FilterTestHelper

  around do |test|
    ApplicationRecord.connection.execute("CREATE TABLE t (test_bool boolean);")
    test.call
    ApplicationRecord.connection.execute("DROP TABLE t;")
  end

  describe "single basic condition" do
    it "gets correct query" do
      query = create_filter(single_condition_blueprint)
      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."text_field_value" = 'aaron')
      SQL
      assert_equal query.get_query.to_sql, convert(expected_sql)
    end
  end

  describe "condition with wrong id" do
    it "adds error" do
      query = TestDoubleFilter.new(bad_id)
      query.conditions = [Hammerstone::Refine::Conditions::TextCondition.new("text_field_value")]
      query.get_query
      assert query.errors.added? :filter, "The condition ID fake was not found"
    end

    it "get_query! raises exception" do
      filter = TestDoubleFilter.new(bad_id)
      filter.conditions = [Hammerstone::Refine::Conditions::TextCondition.new("text_field_value")]
      assert_raises(Hammerstone::Refine::InvalidFilterError) do
        filter.get_query!
      end
    end
  end

  describe "basic filters with ands" do
    it "gets correct query" do
      query = create_filter(and_condition_blueprint)
      assert_equal query.get_query.to_sql, convert(and_sql)
    end
  end

  describe "basic filters with ors" do
    it "gets correct query" do
      query = create_filter(or_condition_blueprint)
      assert_equal query.get_query.to_sql, convert(or_sql)
    end
  end

  describe "basic filter with groups" do
    it "creates filter" do
      query = create_filter(grouped_blueprint)
      assert_equal query.get_query.to_sql, convert(grouped_sql)
    end
  end

  describe "basic filters with nested groups" do
    it "creates filter" do
      query = create_filter(nested_group_blueprint)
      assert_equal query.get_query.to_sql, convert(nested_grouped_sql)
    end
  end

  describe "Configuration object - data going to frontend" do
    describe "Text Condition - no meta, no clauses" do
      it "returns correct json" do
        filter = TestDoubleFilter.new([])
        filter.conditions = [Hammerstone::Refine::Conditions::TextCondition.new("text_field_value")]
        expected_value =
          {
            type: "Hammerstone",
            class_name: "TestDoubleFilter",
            blueprint: [],
            conditions: expected_conditions,
            stable_id: filter.to_stable_id,

          }
        assert_equal expected_value, filter.configuration
      end
    end

    describe "Text Condition with meta, no clauses" do
      it "returns correct json" do
        filter = TestDoubleFilter.new([])
        filter.conditions =
          [Hammerstone::Refine::Conditions::TextCondition.new("text_field_value").with_meta({hint: "password"})]
        expected_value =
          {
            type: "Hammerstone",
            class_name: "TestDoubleFilter",
            blueprint: [],
            conditions: expected_conditions_with_meta,
            stable_id: filter.to_optional_stable_id
          }
        assert_equal expected_value, filter.configuration
      end
    end
  end

  def grouped_sql
    <<~SQL.squish
      SELECT "t".* FROM "t" WHERE (("t"."text_field_value" = 'one') AND (("t"."text_field_value" = 'two') AND ("t"."text_field_value" = 'three')))
    SQL
  end

  def grouped_blueprint
    Hammerstone::Refine::Blueprints::Blueprint.new
      .criterion("text_field_value",
        clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
        value: "one",)
      .and
      .group {
        criterion("text_field_value",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
          value: "two",)
          .and
          .criterion("text_field_value",
            clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
            value: "three",)
      }
  end

  def nested_group_blueprint
    Hammerstone::Refine::Blueprints::Blueprint.new
      .criterion("text_field_value",
        clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
        value: "one",)
      .and
      .group {
        group {
          criterion("text_field_value",
            clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
            value: "two",)
            .and
            .criterion("text_field_value",
              clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
              value: "three",)
        }
          .and
          .criterion("text_field_value",
            clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
            value: "four",)
      }
      .and
      .criterion("text_field_value",
        clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_EQUALS,
        value: "five")
  end

  def create_filter(blueprint)
    BlankTestFilter.new(blueprint,
      FilterTestHelper::TestDouble.all,
      [Hammerstone::Refine::Conditions::TextCondition.new("text_field_value")],
      FilterTestHelper::TestDouble.arel_table)
  end

  def expected_conditions_with_meta
    [
      {
        id: "text_field_value",
        component: "text-condition",
        display: "Text Field Value",
        meta: {
          clauses: [
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
          ],
          hint: "password",
        },
        refinements: []
      }
    ]
  end

  def expected_conditions
    [
      {
        id: "text_field_value",
        component: "text-condition",
        display: "Text Field Value",
        meta: {
          clauses: [
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
        },
        refinements: []
      }
    ]
  end

  def nested_grouped_sql
    <<~SQL.squish
      SELECT "t".* FROM "t" WHERE (("t"."text_field_value" = 'one') AND
      ((("t"."text_field_value" = 'two') AND ("t"."text_field_value" = 'three')) AND ("t"."text_field_value" = 'four'))
      AND ("t"."text_field_value" = 'five'))
    SQL
  end

  def and_sql
    <<~SQL.squish
      SELECT "t".* FROM "t" WHERE (("t"."text_field_value" = 'aaron') AND ("t"."text_field_value" = 'aa'))
    SQL
  end

  def or_sql
    <<~SQL.squish
      SELECT "t".* FROM "t" WHERE (("t"."text_field_value" = 'aaron') OR ("t"."text_field_value" = 'aa'))
    SQL
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
end
