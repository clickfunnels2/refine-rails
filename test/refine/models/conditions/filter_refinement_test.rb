require "test_helper"
require "support/refine/products_filter"
require "support/refine/contacts_filter_test_helper"
require "support/refine/product_contact_relationships"
# Temporarily create a stored_filters_table to test saved filters 
require "support/refine/stored_filters_table"

module Refine::Conditions
  describe "Refinements" do
    include ContactsFilterTestHelper
    # This is an option condition with the path events.type_id and filter refinement
    # of product filters
    let(:option_condition) {
      OptionCondition.new("event_type_id")
        .with_attribute("refine_events.refine_type_id")
        .with_options(
          [{id: "1", display: "Viewed"}, {
            id: "2",
            display: "Purchased"
          }]
        )
        .refine_by_filter(
          FilterCondition.new("refine_events.refine_product._fake")
          .with_scope(Refine::StoredFilter.where(filter_type: "ProductsFilter"))
        )
    }

    around do |test|
      ActiveRecord::Base.connection.execute("CREATE TABLE refine_contacts (id bigint primary key);")
      ActiveRecord::Base.connection.execute("CREATE TABLE refine_products (id bigint primary key, refine_contact_id bigint);")
      ActiveRecord::Base.connection.execute("CREATE TABLE refine_types (id bigint primary key);")
      ActiveRecord::Base.connection.execute("CREATE TABLE refine_events (id bigint primary key, refine_contact_id bigint, refine_type_id bigint, refine_product_id bigint);")
      CreateStoredFiltersTable.new.up
      test.call
      CreateStoredFiltersTable.new.down
      ActiveRecord::Base.connection.execute("DROP TABLE refine_contacts, refine_products, refine_types, refine_events;")
    end

    describe "Filter Refinement" do
      it "works" do
        # Use the full Refine namespace for stabilizers for test environment 
        ENV['NAMESPACE_REFINE_STABILIZERS'] = "1"
        # Must set id here to mimic selecting filter with id "2" on the front-end
        Refine::StoredFilter.find_or_create_by(name: "A filter of an awesome product", state: filter_state, id: 2)
        expected_sql = <<~SQL.squish
          SELECT
            `refine_contacts`.*
          FROM
            `refine_contacts`
          WHERE (`refine_contacts`.`id` IN (SELECT
                `refine_events`.`refine_contact_id` FROM `refine_events`
              WHERE (`refine_events`.`refine_type_id` = 2)
              AND `refine_events`.`refine_product_id` IN (SELECT
                  `refine_products`.`id` FROM `refine_products`
                WHERE (`refine_products`.`name` = 'AwesomeCourse'))))
        SQL

        query = apply_condition_on_test_filter(option_condition, {
          clause: OptionCondition::CLAUSE_EQUALS,
          selected: ["2"],
          filter_refinement: {
            clause: FilterCondition::CLAUSE_IN,
            selected: ["2"]
          }
        }, RefineContact.all, RefineContact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end
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

