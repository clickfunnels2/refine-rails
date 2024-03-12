require "test_helper"
require "support/refine/products_filter"
require "support/refine/contacts_filter_test_helper"
require "support/refine/product_contact_relationships"
require "support/refine/stored_filters_table"

module Refine::Conditions
  describe "Filter Condition" do
    include ContactsFilterTestHelper

    let(:condition_under_test) {
      FilterCondition.new("refine_products.filter")
        .with_scope(Refine::StoredFilter.where(filter_type: "ProductsFilter"))
    }

    around do |test|
      ActiveRecord::Base.connection.execute("CREATE TABLE refine_contacts (id bigint primary key);")
      ActiveRecord::Base.connection.execute("CREATE TABLE refine_products (id bigint primary key, refine_contact_id bigint);")
      CreateStoredFiltersTable.new.up
      test.call
      CreateStoredFiltersTable.new.down
      ActiveRecord::Base.connection.execute("DROP TABLE refine_contacts, refine_products;")
    end

    it "accepts a filter" do
      ENV['NAMESPACE_REFINE_STABILIZERS'] = "1"
      Refine::StoredFilter.destroy_all
      Refine::StoredFilter.create(name: "A filter of an awesome product", state: filter_state, id: 2,filter_type: "ProductsFilter")

      data = {clause: FilterCondition::CLAUSE_IN, selected: ["2"]}
      expected_sql = <<~SQL.squish
        SELECT
          `refine_contacts`.*
        FROM
          `refine_contacts`
        WHERE (`refine_contacts`.`id` IN (SELECT
              `refine_products`.`refine_contact_id` FROM `refine_products`
            WHERE (`refine_products`.`name` = 'AwesomeCourse')))
      SQL

      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    def filter_state
      {
        type: "ProductsFilter",
        blueprint: blueprint
      }.to_json
    end

    def blueprint
     [{
       "depth": 1,
       "type": "criterion",
       "condition_id": "name",
       "input":
       {
         "clause": "eq",
         "value": "AwesomeCourse"
       },
       "position": 0
     }]
    end
  end
end
