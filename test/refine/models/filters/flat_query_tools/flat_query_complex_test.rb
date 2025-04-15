require "test_helper"
require "support/refine/test_double_filter"
require "support/refine/contact_complex_relationships"
require "refine/invalid_filter_error"

describe Refine::Filter do
  include FilterTestHelper

  around do |test|
    ApplicationRecord.connection.execute("CREATE TABLE contacts (id bigint primary key, text_field_value varchar(255));")
    ApplicationRecord.connection.execute("CREATE TABLE contacts_applied_tags (id bigint primary key, contact_id bigint, tag_id bigint);")
    ApplicationRecord.connection.execute("CREATE TABLE contacts_tags (id bigint primary key);")
    ApplicationRecord.connection.execute("CREATE TABLE contacts_last_activities (id bigint primary key);")
    ApplicationRecord.connection.execute("CREATE TABLE products (id bigint primary key);")
    ApplicationRecord.connection.execute("CREATE TABLE orders (id bigint primary key, contact_id bigint, service_status varchar(255));")
    ApplicationRecord.connection.execute("CREATE TABLE orders_line_items (id bigint primary key, order_id bigint, original_product_id bigint);")
    ApplicationRecord.connection.execute("CREATE TABLE forms_submissions (id bigint primary key, contact_id bigint, form_id bigint, submitted_at datetime);")
    test.call
    ApplicationRecord.connection.execute("DROP TABLE contacts, contacts_applied_tags, contacts_tags, contacts_last_activities, products, orders, orders_line_items, forms_submissions;")
  end

  describe "get_flat_query" do
    it "handles complex query with multiple conditions and joins" do
      initial_query = Contact.all
      filter = create_filter(complex_criteria)

      expected_sql = <<-SQL.squish
        SELECT DISTINCT `contacts`.* FROM `contacts`
          INNER JOIN `contacts_applied_tags` `contacts_applied_tags_1` ON `contacts_applied_tags_1`.`contact_id` = `contacts`.`id` AND `contacts_applied_tags_1`.`tag_id` IN (1, 2)
          INNER JOIN `contacts_applied_tags` `contacts_applied_tags_2` ON `contacts_applied_tags_2`.`contact_id` = `contacts`.`id` AND `contacts_applied_tags_2`.`tag_id` = 4
          INNER JOIN `orders` ON `orders`.`contact_id` = `contacts`.`id`
          INNER JOIN `orders_line_items` ON `orders_line_items`.`order_id` = `orders`.`id`
          WHERE (`contacts`.`text_field_value` = 'aaron')
            AND (`orders`.`service_status` = 'active')
            AND (`orders_line_items`.`original_product_id` = 123)
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql
    end

    it "handles forms submissions with date range" do
      initial_query = Contact.all
      filter = create_filter(forms_submissions_criteria)

      expected_sql = <<-SQL.squish
        SELECT DISTINCT `contacts`.* FROM `contacts`
          INNER JOIN `forms_submissions` ON `forms_submissions`.`contact_id` = `contacts`.`id`
          WHERE (`forms_submissions`.`form_id` = 1)
            AND (`forms_submissions`.`submitted_at` >= '2023-01-01 00:00:00')
            AND (`forms_submissions`.`submitted_at` <= '2023-12-31 23:59:59')
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql
    end

    it "handles multiple forms submissions with different conditions" do
      initial_query = Contact.all
      filter = create_filter(multiple_forms_submissions_criteria)

      expected_sql = <<-SQL.squish
        SELECT DISTINCT `contacts`.* FROM `contacts`
          INNER JOIN `forms_submissions` `forms_submissions_1` 
            ON `forms_submissions_1`.`contact_id` = `contacts`.`id` 
            AND `forms_submissions_1`.`form_id` = 1 
            AND `forms_submissions_1`.`submitted_at` >= '2023-01-01 00:00:00'
          INNER JOIN `forms_submissions` `forms_submissions_2` 
            ON `forms_submissions_2`.`contact_id` = `contacts`.`id` 
            AND `forms_submissions_2`.`form_id` = 2 
            AND `forms_submissions_2`.`submitted_at` <= '2023-12-31 23:59:59'
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
        Refine::Conditions::OptionCondition.new("tags.id").with_options(proc { tag_options }),
        Refine::Conditions::TextCondition.new("orders.service_status"),
        Refine::Conditions::TextCondition.new("orders_line_items.original_product_id"),
        Refine::Conditions::TextCondition.new("forms_submissions.form_id"),
        Refine::Conditions::DateCondition.new("forms_submissions.submitted_at")
      ],
      Contact.arel_table)
  end

  def complex_criteria
    [
      # First tag condition (IN)
      {
        depth: 0,
        type: "criterion",
        condition_id: "tags.id",
        input: {
          clause: "in",
          selected: ["1", "2"]
        }
      },
      # AND conjunction
      {
        depth: 0,
        type: "conjunction",
        word: "and"
      },
      # Second tag condition (EQ)
      {
        depth: 0,
        type: "criterion",
        condition_id: "tags.id",
        input: {
          clause: "eq",
          selected: ["4"]
        }
      },
      # AND conjunction
      {
        depth: 0,
        type: "conjunction",
        word: "and"
      },
      # Text field condition
      {
        depth: 0,
        type: "criterion",
        condition_id: "text_field_value",
        input: {
          clause: "eq",
          value: "aaron"
        }
      },
      # AND conjunction
      {
        depth: 0,
        type: "conjunction",
        word: "and"
      },
      # Order service status condition
      {
        depth: 0,
        type: "criterion",
        condition_id: "orders.service_status",
        input: {
          clause: "eq",
          value: "active"
        }
      },
      # AND conjunction
      {
        depth: 0,
        type: "conjunction",
        word: "and"
      },
      # Order line item condition
      {
        depth: 0,
        type: "criterion",
        condition_id: "orders_line_items.original_product_id",
        input: {
          clause: "eq",
          value: "123"
        }
      }
    ]
  end

  def forms_submissions_criteria
    [
      {
        depth: 0,
        type: "criterion",
        condition_id: "forms_submissions.form_id",
        input: {
          clause: "eq",
          value: "1"
        }
      },
      {
        depth: 0,
        type: "conjunction",
        word: "and"
      },
      {
        depth: 0,
        type: "criterion",
        condition_id: "forms_submissions.submitted_at",
        input: {
          clause: "gte",
          value: "2023-01-01"
        }
      },
      {
        depth: 0,
        type: "conjunction",
        word: "and"
      },
      {
        depth: 0,
        type: "criterion",
        condition_id: "forms_submissions.submitted_at",
        input: {
          clause: "lte",
          value: "2023-12-31"
        }
      }
    ]
  end

  def multiple_forms_submissions_criteria
    [
      {
        depth: 0,
        type: "criterion",
        condition_id: "forms_submissions.form_id",
        input: {
          clause: "eq",
          value: "1"
        }
      },
      {
        depth: 0,
        type: "conjunction",
        word: "and"
      },
      {
        depth: 0,
        type: "criterion",
        condition_id: "forms_submissions.submitted_at",
        input: {
          clause: "gte",
          value: "2023-01-01"
        }
      },
      {
        depth: 0,
        type: "conjunction",
        word: "and"
      },
      {
        depth: 0,
        type: "criterion",
        condition_id: "forms_submissions.form_id",
        input: {
          clause: "eq",
          value: "2"
        }
      },
      {
        depth: 0,
        type: "conjunction",
        word: "and"
      },
      {
        depth: 0,
        type: "criterion",
        condition_id: "forms_submissions.submitted_at",
        input: {
          clause: "lte",
          value: "2023-12-31"
        }
      }
    ]
  end
end 