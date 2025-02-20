require "test_helper"
require "support/refine/filter_test_helper"

module Refine::Conditions::ComplexAssociations
  describe "Has Many Through Test" do
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

    it "properly handles IS ONE OF option conditions" do 
      query = create_filter(contains_option_condition)
      expected_sql = <<~SQL.squish
        SELECT
          `contacts`.*
        FROM
          `contacts`
        WHERE (`contacts`.`id` IN (SELECT
                `contacts`.`id` FROM `contacts`
                INNER JOIN `contacts_applied_tags` ON `contacts_applied_tags`.`contact_id` = `contacts`.`id`
                INNER JOIN `contacts_tags` ON `contacts_tags`.`id` = `contacts_applied_tags`.`tag_id`
              WHERE (`contacts_tags`.`id` IN (1))))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "properly handles IS ONE OF option conditions with through shortcut" do 
      query = create_filter_with_through_id(contains_option_condition)
      expected_sql = <<~SQL.squish
        SELECT
          `contacts`.*
        FROM
          `contacts`
        WHERE (`contacts`.`id` IN (SELECT
                `contacts_applied_tags`.`contact_id` FROM `contacts_applied_tags`
              WHERE (`contacts_applied_tags`.`tag_id` IN (1))))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "properly handles negative option conditions" do 
      query = create_filter(does_not_contain_option_condition)
      expected_sql = <<~SQL.squish
        SELECT
          `contacts`.*
        FROM
          `contacts`
        WHERE (`contacts`.`id` NOT IN (SELECT
                `contacts`.`id` FROM `contacts`
                INNER JOIN `contacts_applied_tags` ON `contacts_applied_tags`.`contact_id` = `contacts`.`id`
                INNER JOIN `contacts_tags` ON `contacts_tags`.`id` = `contacts_applied_tags`.`tag_id`
              WHERE (`contacts_tags`.`id` IN (1))))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "properly handles negative option conditions with through id set" do 
      # TODO 
      query = create_filter_with_through_id(does_not_contain_option_condition)
      expected_sql = <<~SQL.squish
        SELECT
          `contacts`.*
        FROM
          `contacts`
        WHERE (`contacts`.`id` NOT IN (SELECT
                `contacts_applied_tags`.`contact_id` FROM `contacts_applied_tags`
              WHERE (`contacts_applied_tags`.`tag_id` IN (1))))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "properly handles negative option conditions with through id set and forced index" do 
      # TODO 
      query = create_filter_with_through_id_forced_index(does_not_contain_option_condition, "index_contacts_applied_tags_on_contact_id")
      expected_sql = <<~SQL.squish
        SELECT
          `contacts`.*
        FROM
          `contacts`
        WHERE (`contacts`.`id` NOT IN (SELECT
                `contacts_applied_tags`.`contact_id` FROM `contacts_applied_tags`
                FORCE INDEX(`index_contacts_applied_tags_on_contact_id`)
              WHERE (`contacts_applied_tags`.`tag_id` IN (1))))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "properly handles negative option conditions with through id set on a nested relationship" do 
      # TODO 
      query = create_nested_through_id(does_not_contain_option_condition_nested)
      expected_sql = <<~SQL.squish
        SELECT
          `contacts`.*
        FROM
          `contacts`
        WHERE (`contacts`.`id` NOT IN (SELECT `orders`.`contact_id` FROM `orders`
          INNER JOIN `orders_line_items` ON `orders_line_items`.`order_id` = `orders`.`id` 
          WHERE `orders`.`service_status` IN ('churned', 'canceled') 
            AND (`orders_line_items`.`original_product_id` IN (2, 6505))))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    def does_not_contain_option_condition
      Refine::Blueprints::Blueprint.new
        .criterion("tags.id",
          clause: Refine::Conditions::OptionCondition::CLAUSE_NOT_IN,
          selected: ["1"])
    end

    def does_not_contain_option_condition_nested
      Refine::Blueprints::Blueprint.new
        .criterion("churned_products.id",
          clause: Refine::Conditions::OptionCondition::CLAUSE_NOT_IN,
          selected: ["6505", "2"])
    end

    def contains_option_condition
      Refine::Blueprints::Blueprint.new
        .criterion("tags.id",
          clause: Refine::Conditions::OptionCondition::CLAUSE_IN,
          selected: ["1"])
    end

    def create_filter(blueprint)
      # Contacts Filter
      BlankTestFilter.new(blueprint,
        Contact.all,
        [
          Refine::Conditions::OptionCondition.new("tags.id").with_options([{id: "1", display: "Option 1"}])
        ],
        Contact.arel_table)
    end

    def create_filter_with_through_id(blueprint)
      # Contacts Filter
      BlankTestFilter.new(blueprint,
        Contact.all,
        [
          Refine::Conditions::OptionCondition.new("tags.id").with_options([{id: "1", display: "Option 1"}]).with_through_id_relationship
        ],
        Contact.arel_table)
    end

    def create_filter_with_through_id_forced_index(blueprint, index)
      # Contacts Filter
      BlankTestFilter.new(blueprint,
        Contact.all,
        [
          Refine::Conditions::OptionCondition.new("tags.id").with_options([{id: "1", display: "Option 1"}]).with_through_id_relationship.with_forced_index(index)
        ],
        Contact.arel_table)
    end

    def create_invalid_through_id_association(blueprint)
      BlankTestFilter.new(blueprint,
      Contact.all,
      [
        Refine::Conditions::OptionCondition.new("last_activity.last_activity_at").with_options([{id: "1", display: "Option 1"}]).with_through_id_relationship
      ],
      Contact.arel_table) 
    end

    def create_nested_through_id(blueprint)
      BlankTestFilter.new(blueprint,
        Contact.all,
        [
          Refine::Conditions::OptionCondition.new("churned_products.id").with_options([{id: "2", display: "Option 2"}, {id: "6505", display: "Option 6505"}]).with_through_id_relationship
        ],
        Contact.arel_table) 
    end
  end

  class Contact < ActiveRecord::Base
    has_many :applied_tags, class_name: "Refine::Conditions::ComplexAssociations::Contact::AppliedTag", dependent: :destroy
    has_many :tags, through: :applied_tags

    has_many :orders
    has_many :line_items, through: :orders
    has_many :products, through: :line_items, source: :original_product
    has_many :churned_line_items, -> { where(orders: {service_status: %w[churned canceled]}) }, through: :orders, source: :line_items
    has_many :churned_products, through: :churned_line_items, source: :original_product

    has_one :last_activity, class_name: "Refine::Conditions::ComplexAssociations::Contact::LastActivity", dependent: :destroy
  end

  class Contact::AppliedTag < ActiveRecord::Base
    belongs_to :contact, touch: true
    belongs_to :tag, class_name: "Refine::Conditions::ComplexAssociations::Contact::Tag"
    self.table_name = "contacts_applied_tags"
  end

  class Contact::Tag < ActiveRecord::Base
    has_many :applied_tags, class_name: "Refine::Conditions::ComplexAssociations::Contact::AppliedTag", dependent: :destroy
    has_many :contacts, through: :applied_tags
    self.table_name = "contacts_tags"
  end

  class Contact::LastActivity < ActiveRecord::Base
    belongs_to :contact, touch: true, optional: true
  end

  class Order < ActiveRecord::Base
    belongs_to :contact
    has_many :line_items, class_name: "Refine::Conditions::ComplexAssociations::Orders::LineItem", dependent: :destroy
  end

  class Product < ActiveRecord::Base
  end

  module Orders
    def self.table_name_prefix
      "orders_"
    end
  end

  class Orders::LineItem < ActiveRecord::Base
    belongs_to :order, class_name: "Refine::Conditions::ComplexAssociations::Order"
    belongs_to :original_product, class_name: "Refine::Conditions::ComplexAssociations::Product"
  end
end
