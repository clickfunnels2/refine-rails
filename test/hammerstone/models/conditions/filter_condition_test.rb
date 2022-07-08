require "test_helper"
require "support/hammerstone/hammerstone_products_filter"
require "support/hammerstone/hammerstone_contacts_filter_test_helper"
require "support/hammerstone/hammerstone_product_contact_relationships"
require "support/hammerstone/stored_filters_table"

module Hammerstone::Refine::Conditions
  describe "Filter Condition" do
    include HammerstoneContactsFilterTestHelper

    let(:condition_under_test) {
      FilterCondition.new("hammerstone_products.filter")
        .with_scope(Hammerstone::Refine::StoredFilter.where(filter_type: "HammerstoneProductsFilter"))
    }

    around do |test|
      ActiveRecord::Base.connection.execute("CREATE TABLE hammerstone_contacts (id bigint primary key);")
      ActiveRecord::Base.connection.execute("CREATE TABLE hammerstone_products (id bigint primary key, hammerstone_contact_id bigint);")
      CreateStoredFiltersTable.new.up
      test.call
      CreateStoredFiltersTable.new.down
      ActiveRecord::Base.connection.execute("DROP TABLE hammerstone_contacts, hammerstone_products;")
    end

    it "accepts a filter" do
      ENV['NAMESPACE_REFINE_STABILIZERS'] = "1"
      Hammerstone::Refine::StoredFilter.destroy_all
      Hammerstone::Refine::StoredFilter.create(name: "A filter of an awesome product", state: filter_state, id: 2,filter_type: "HammerstoneProductsFilter")
      puts "filter condition test"

      data = {clause: FilterCondition::CLAUSE_IN, selected: ["2"]}
      expected_sql = <<~SQL.squish
        SELECT
          `hammerstone_contacts`.*
        FROM
          `hammerstone_contacts`
        WHERE (`hammerstone_contacts`.`id` IN (SELECT
              `hammerstone_products`.`hammerstone_contact_id` FROM `hammerstone_products`
            WHERE (`hammerstone_products`.`name` = 'AwesomeCourse')))
      SQL

      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    def filter_state
      {
        type: "HammerstoneProductsFilter",
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
