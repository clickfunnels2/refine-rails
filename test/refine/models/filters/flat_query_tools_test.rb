require "test_helper"
require "support/refine/test_double_filter"
require "support/refine/contact_complex_relationships"
require "refine/invalid_filter_error"
require 'mocha/minitest'

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
            WHERE (`contacts_applied_tags`.`tag_id` = 1)
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
            WHERE (`contacts_applied_tags`.`tag_id` = 1) 
        SQL
        assert_equal  expected_sql, filter.get_flat_query.to_sql
      end
    end
  end

  def create_filter(blueprint=nil)
    FlatQueryTestFilter.new(blueprint,
      Contact.all,
      [
        Refine::Conditions::TextCondition.new("text_field_value"),
        Refine::Conditions::OptionCondition.new("tags.id").with_options(proc { [{id: "1", display: "tag1"}, {id: "2", display: "tag2"}, {id: "3", display: "tag3"}, {id: "4", display: "tag4"}] })
      ],
      Contact.arel_table)
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

  describe "flat query fallback and selection" do
    it "falls back to complex query if OR is present" do
      # Setup a blueprint with an OR conjunction
      blueprint = [
        {
          depth: 0,
          type: "criterion",
          condition_id: "tags.id",
          input: {
            clause: "in",
            selected: ["1", "2"]
          }
        },
        {
          depth: 0,
          type: "conjunction",
          word: "or"
        },
        {
          depth: 0,
          type: "criterion",
          condition_id: "tags.id",
          input: {
            clause: "eq",
            selected: ["4"]
          }
        }
      ]
      filter = create_filter(blueprint)
      # Force can_use_get_query to return false for this test
      filter.stubs(:can_use_get_query?).returns(false)
      # Should use the complex query logic, not flat
      assert_equal filter.get_complex_query.to_sql, filter.get_query.to_sql
    end

    it "uses flat query for simple AND tags filter" do
      blueprint = [
        {
          depth: 0,
          type: "criterion",
          condition_id: "tags.id",
          input: {
            clause: "in",
            selected: ["1", "2"]
          }
        }
      ]
      filter = create_filter(blueprint)
      # Force can_use_get_query to return true for this test
      filter.stubs(:can_use_get_query?).returns(true)
      # Should use the flat query logic
      assert_equal filter.get_flat_query.to_sql, filter.get_query.to_sql
    end
  end
end
