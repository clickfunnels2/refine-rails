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
    it "two separate criteria referencing tags generates a proper query" do
      initial_query = Contact.all
      filter = create_filter(two_tag_criteria)

      expected_sql = <<-SQL.squish
        SELECT DISTINCT `contacts`.* FROM `contacts` 
          INNER JOIN `contacts_applied_tags` `contacts_applied_tags_1` ON `contacts_applied_tags_1`.`contact_id` = `contacts`.`id` AND (`contacts_applied_tags_1`.`tag_id` IN (1, 2))
          INNER JOIN `contacts_applied_tags` `contacts_applied_tags_2` ON `contacts_applied_tags_2`.`contact_id` = `contacts`.`id` AND (`contacts_applied_tags_2`.`tag_id` = 4)
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql
    end
    
    it "single criteria referencing tags does not add alias" do
      initial_query = Contact.all
      filter = create_filter(single_tag_criteria)

      expected_sql = <<-SQL.squish
        SELECT DISTINCT `contacts`.* FROM `contacts`
          INNER JOIN `contacts_applied_tags` ON `contacts_applied_tags`.`contact_id` = `contacts`.`id`
          WHERE (`contacts_applied_tags`.`tag_id` IN (1, 2))
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql
    end
  end

  def create_filter(blueprint=nil)
    tag_options = [{id: "1", display: "tag1"}, {id: "2", display: "tag2"}, {id: "3", display: "tag3"}, {id: "4", display: "tag4"}]
    BlankTestFilter.new(blueprint,
      Contact.all,
      [
        Refine::Conditions::TextCondition.new("text_field_value"),
        Refine::Conditions::OptionCondition.new("tags.id").with_options(proc { tag_options })
      ],
      Contact.arel_table)
  end

  def single_tag_criteria
    [{
      depth: 0,
      type: "criterion",
      condition_id: "tags.id",
      input: {
        clause: "in",
        selected: ["1", "2"]
      }
    }]
  end

  def two_tag_criteria
    [{
      depth: 0,
      type: "criterion",
      condition_id: "tags.id",
      input: {
        clause: "in",
        selected: ["1", "2"]
      }
    }, { # conjunction
      depth: 0,
      type: "conjunction",
      word: "and"
    }, {
      depth: 0,
      type: "criterion",
      condition_id: "tags.id",
      input: {
        clause: "eq",
        selected: ["4"]
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
