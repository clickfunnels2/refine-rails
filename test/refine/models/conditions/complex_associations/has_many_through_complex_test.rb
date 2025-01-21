require "test_helper"
require "support/refine/filter_test_helper"

module Refine::Conditions::ComplexAssociations
  describe "Has Many Through ComplexTest" do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE products (id bigint primary key);")
      ApplicationRecord.connection.execute("CREATE TABLE products_variants (id bigint primary key, product_id bigint);")
      ApplicationRecord.connection.execute("CREATE TABLE orders (id bigint primary key, contact_id bigint, service_status varchar(255));")
      ApplicationRecord.connection.execute("CREATE TABLE orders_line_items (id bigint primary key, order_id bigint, original_product_id bigint);")
      ApplicationRecord.connection.execute("CREATE TABLE orders_transactions (id bigint primary key, order_id bigint);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE products, orders, orders_line_items, orders_transactions, products_variants;")
    end


    it "properly handles negative option conditions with through id set on a nested relationship" do 
      # TODO 
      query = create_nested_through_products(does_not_contain_option_condition_nested)
      expected_sql = <<~SQL.squish
      SELECT
        `orders_transactions`.*
      FROM
        `orders_transactions`
      WHERE (`orders_transactions`.`id` NOT IN (SELECT 
            `orders_line_items`.`order_id` FROM `orders_line_items`
          WHERE (`orders_line_items`.`original_product_id` IN (2, 6505))))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "properly handles positive option conditions with through id set on a nested relationship" do 
      # TODO 
      query = create_nested_through_variants(contain_option_condition_nested)
      expected_sql = <<~SQL.squish
      SELECT
        `orders_transactions`.*
      FROM
        `orders_transactions`
      WHERE (`orders_transactions`.`id` IN (SELECT 
            `orders_line_items`.`order_id` FROM `orders_line_items`
          WHERE (`orders_line_items`.`variant_id` IN ('4', '505'))))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    def does_not_contain_option_condition_nested
      Refine::Blueprints::Blueprint.new
        .criterion("products.id",
          clause: Refine::Conditions::OptionCondition::CLAUSE_NOT_IN,
          selected: ["6505", "2"])
    end

    def contain_option_condition_nested
      Refine::Blueprints::Blueprint.new
        .criterion("purchased_variants.id",
          clause: Refine::Conditions::OptionCondition::CLAUSE_IN,
          selected: ["505", "4"])
    end

    def create_nested_through_products(blueprint)
      BlankTestFilter.new(blueprint,
        Orders::Transaction.all,
        [
          Refine::Conditions::OptionCondition.new("products.id").with_options([{id: "2", display: "Option 2"}, {id: "6505", display: "Option 6505"}]).with_through_id_relationship
        ],
        Orders::Transaction.arel_table) 
    end
    
    def create_nested_through_variants(blueprint)
      BlankTestFilter.new(blueprint,
        Orders::Transaction.all,
        [
          Refine::Conditions::OptionCondition.new("purchased_variants.id").with_options([{id: "4", display: "Option 4"}, {id: "505", display: "Option 505"}]).with_through_id_relationship
        ],
        Orders::Transaction.arel_table) 
    end
  end

  class Transaction < ActiveRecord::Base
    belongs_to :order
    has_many :products, through: :order
    has_many :purchased_variants, through: :order
  end

  class Order < ActiveRecord::Base
    belongs_to :contact
    has_many :line_items, class_name: "Refine::Conditions::ComplexAssociations::Orders::LineItem", dependent: :destroy
    has_many :products, through: :line_items, source: :original_product
    has_many :purchased_variants, class_name: "Refine::Conditions::ComplexAssociations::Products::Variant", through: :line_items, source: :variant
    has_many :transactions, class_name: "Refine::Conditions::ComplexAssociations::Orders::Transaction", dependent: :destroy, foreign_key: :order_id
  end

  class Product < ActiveRecord::Base
  end

  module Products
    def self.table_name_prefix
      "products_"
    end
  end

  class Products::Variant < ActiveRecord::Base
    belongs_to :product, class_name: "Refine::Conditions::ComplexAssociations::Product", inverse_of: :variants
  end

  module Orders
    def self.table_name_prefix
      "orders_"
    end
  end

  class Orders::LineItem < ActiveRecord::Base
    belongs_to :order, class_name: "Refine::Conditions::ComplexAssociations::Order"
    belongs_to :original_product, class_name: "Refine::Conditions::ComplexAssociations::Product"
    belongs_to :variant, class_name: "Refine::Conditions::ComplexAssociations::Products::Variant"
  end

  class Orders::Transaction < ActiveRecord::Base
    belongs_to :order, class_name: "Refine::Conditions::ComplexAssociations::Order"
    has_many :products, through: :order
    has_many :purchased_variants, through: :order
  end
end
