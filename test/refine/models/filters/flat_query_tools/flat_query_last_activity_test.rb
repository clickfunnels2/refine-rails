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
    ApplicationRecord.connection.execute("CREATE TABLE contacts_last_activities (id bigint primary key, last_activity_at datetime);")
    test.call
    ApplicationRecord.connection.execute("DROP TABLE contacts, contacts_applied_tags, contacts_tags, contacts_last_activities;")
  end

  describe "get_flat_query" do
    it "referencing an attribute on a related table thats not the primary key generates a proper query" do
      initial_query = Contact.all
      filter = create_filter(last_activity_criteria)

      expected_sql = <<-SQL.squish
        SELECT DISTINCT `contacts`.* FROM `contacts` 
          INNER JOIN `contacts_last_activities` ON `contacts_last_activities`.`contact_id` = `contacts`.`id` 
          WHERE ((`contacts_last_activities`.`last_activity_at` BETWEEN '2020-01-01 00:00:00' AND '2020-01-01 23:59:59'))
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql
    end

    it "combining with another relational condition still generates the correct query" do
      initial_query = Contact.all
      filter = create_filter(last_activity_criteria_and_tag)

      expected_sql = <<-SQL.squish
        SELECT DISTINCT `contacts`.* FROM `contacts` 
          INNER JOIN `contacts_last_activities` ON `contacts_last_activities`.`contact_id` = `contacts`.`id` 
          INNER JOIN `contacts_applied_tags` ON `contacts_applied_tags`.`contact_id` = `contacts`.`id` 
          WHERE ((`contacts_last_activities`.`last_activity_at` BETWEEN '2020-01-01 00:00:00' AND '2020-01-01 23:59:59')) AND ((`contacts_applied_tags`.`tag_id` = 4))
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
        Refine::Conditions::DateWithTimeCondition.new("last_activity.last_activity_at")
      ],
      Contact.arel_table)
  end

  def last_activity_criteria
    [{
      depth: 0,
      type: "criterion",
      condition_id: "last_activity.last_activity_at",
      input: {
        clause: "eq",
        date1: "2020-01-01"
      }
    }]
  end

  def last_activity_criteria_and_tag
    [{
      depth: 0,
      type: "criterion",
      condition_id: "last_activity.last_activity_at",
      input: {
        clause: "eq",
        date1: "2020-01-01"
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

end
