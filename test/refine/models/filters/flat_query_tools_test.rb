require "test_helper"
require "support/refine/test_double_filter"
require "support/refine/contact_complex_relationships"
require "refine/invalid_filter_error"

describe Refine::Filter do
  include FilterTestHelper

  around do |test|
    ApplicationRecord.connection.execute("CREATE TABLE contacts (id bigint primary key);")
    ApplicationRecord.connection.execute("CREATE TABLE contacts_applied_tags (id bigint primary key, contact_id bigint, tag_id bigint);")
    ApplicationRecord.connection.execute("CREATE TABLE contacts_tags (id bigint primary key);")
    ApplicationRecord.connection.execute("CREATE TABLE contacts_last_activities (id bigint primary key);")
    ApplicationRecord.connection.execute("CREATE TABLE products (id bigint primary key);")
    ApplicationRecord.connection.execute("CREATE TABLE orders (id bigint primary key, contact_id bigint, service_status varchar(255));")
    ApplicationRecord.connection.execute("CREATE TABLE orders_line_items (id bigint primary key, order_id bigint, original_product_id bigint);")
    test.call
    ApplicationRecord.connection.execute("DROP TABLE contacts, contacts_applied_tags, contacts_tags, contacts_last_activities, products, orders, orders_line_items;")
  end

  describe "get_flat_query" do
    it "raises an error if the initial query is nil" do
      query = create_filter(single_condition_blueprint)
      query.instance_variable_set(:@initial_query, nil)
      assert_raises(RuntimeError) { query.get_flat_query }
    end

    it "raises an error if the filter uses OR conditions" do
      query = create_filter(or_condition_blueprint)
      assert_raises(RuntimeError) { query.get_flat_query } 
    end

    it "returns the relation if the blueprint is nil" do
      initial_query = Contact.all
      filter = create_filter
      assert_equal filter.get_flat_query.to_sql, initial_query.to_sql
    end

    describe "with a single-condition blueprint" do
      it "returns the relation with the condition applied" do
        initial_query = Contact.all
        filter = create_filter(single_tag_blueprint)
        expected_sql = <<-SQL.squish
          SELECT DISTINCT `contacts`.* FROM `contacts` 
            INNER JOIN `contacts_applied_tags` ON `contacts_applied_tags`.`contact_id` = `contacts`.`id` 
            WHERE ((`contacts_applied_tags`.`tag_id` = 1))
        SQL
        assert_equal expected_sql, filter.get_flat_query.to_sql
      end

      it "calling get_flat_query twice is idempotent" do
        initial_query = Contact.all
        filter = create_filter(single_tag_blueprint)
        filter.get_flat_query
        expected_sql = <<-SQL.squish
          SELECT DISTINCT `contacts`.* FROM `contacts` 
            INNER JOIN `contacts_applied_tags` ON `contacts_applied_tags`.`contact_id` = `contacts`.`id` 
            WHERE ((`contacts_applied_tags`.`tag_id` = 1)) 
        SQL
        assert_equal  expected_sql, filter.get_flat_query.to_sql
      end
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
      Contact.all,
      [
        Refine::Conditions::TextCondition.new("text_field_value"),
        Refine::Conditions::OptionCondition.new("tags.id").with_options(proc { [{id: "1", display: "tag1"}] })
      ],
      Contact.arel_table)
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

  def single_tag_blueprint
    [{
      depth: 0,
      type: "criterion",
      condition_id: "tags.id",
      input: {
        clause: "eq",
        selected: ["1"]
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
end
