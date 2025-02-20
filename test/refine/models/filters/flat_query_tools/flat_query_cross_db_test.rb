require "test_helper"
require "support/refine/test_double_filter"
require "support/refine/contact_complex_relationships"
require "refine/invalid_filter_error"
require 'minitest/autorun'
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
    ApplicationRecord.connection.execute("CREATE TABLE events (id bigint primary key auto_increment, source_id bigint, contact_id bigint);")
    test.call
    ApplicationRecord.connection.execute("DROP TABLE contacts, contacts_applied_tags, contacts_tags, contacts_last_activities, products, orders, orders_line_items, events;")
  end

  describe "get_flat_query with a cross-db lookup" do
    it "properly constructs the initial query before applying the condition" do
      initial_query = Contact.all
      filter = create_filter(event_blueprint)
      Refine::Conditions::Condition.any_instance.stubs(:condiiton_uses_different_database?).returns(true)
      executed_queries = []
      original_execute = Event.connection.method(:execute)

      expected_event_sql = <<-SQL.squish
        SELECT `events`.`contact_id` FROM `events`
          WHERE (`events`.`source_id` IN (1, 2))
      SQL

      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
        executed_queries << payload[:sql]
      end

      filter.get_flat_query

      assert executed_queries.any? { |sql| sql.include?(expected_event_sql)  }, "Expected to find the event query in the executed queries: #{expected_event_sql}"

    end

    it "single check " do
      initial_query = Contact.all
      Event.create(source_id: 1, contact_id: 50)
      filter = create_filter(event_blueprint)
      Refine::Conditions::Condition.any_instance.stubs(:condiiton_uses_different_database?).returns(true)

      expected_sql = <<-SQL.squish
        SELECT `contacts`.* FROM `contacts` 
          WHERE (`contacts`.`id` = 50)
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql
    end

    it "multi-result check" do
      initial_query = Contact.all
      Event.create(source_id: 1, contact_id: 50)
      Event.create(source_id: 1, contact_id: 51)
      filter = create_filter(event_blueprint)
      Refine::Conditions::Condition.any_instance.stubs(:condiiton_uses_different_database?).returns(true)

      expected_sql = <<-SQL.squish
        SELECT `contacts`.* FROM `contacts` 
          WHERE (`contacts`.`id` IN (50, 51))
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql    
    end

    it "multi-condition check" do
      initial_query = Contact.all
      Event.create(source_id: 1, contact_id: 50)
      Event.create(source_id: 2, contact_id: 51)
      Event.create(source_id: 5, contact_id: 50)
      filter = create_filter(multi_event_blueprint)
      Refine::Conditions::Condition.any_instance.stubs(:condiiton_uses_different_database?).returns(true)

      expected_sql = <<-SQL.squish
        SELECT `contacts`.* FROM `contacts` 
          WHERE (`contacts`.`id` IN (50, 51)) AND (`contacts`.`id` = 50)
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql     
    end
    
  end

  def create_filter(blueprint=nil)
    tag_options = [{id: "1", display: "tag1"}, {id: "2", display: "tag2"}, {id: "3", display: "tag3"}, {id: "4", display: "tag4"}]
    event_source_options = [{id: "1", display: "source1"}, {id: "2", display: "source2"}, {id: "5", display: "source5"}]
    BlankTestFilter.new(blueprint,
      Contact.all,
      [
        Refine::Conditions::TextCondition.new("text_field_value"),
        Refine::Conditions::OptionCondition.new("tags.id").with_options(proc { tag_options }),
        Refine::Conditions::OptionCondition.new("events.source_id").with_options(proc { event_source_options })
      ],
      Contact.arel_table)
  end

  def event_blueprint
    [{
      depth: 0,
      type: "criterion",
      condition_id: "events.source_id",
      input: {
        clause: "in",
        selected: ["1", "2"]
      }
    }]
  end

  def multi_event_blueprint
    [{
      depth: 0,
      type: "criterion",
      condition_id: "events.source_id",
      input: {
        clause: "in",
        selected: ["1", "2"]
      }
    }, {
      depth: 0,
      type: "conjunction",
      word: "and"
    }, {
      depth: 0,
      type: "criterion",
      condition_id: "events.source_id",
      input: {
        clause: "eq",
        selected: ["5"]
      }
    }]
  end

end
