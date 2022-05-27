require "test_helper"
require "support/hammerstone/hammerstone_products_filter"
require "support/hammerstone/hammerstone_contacts_filter_test_helper"
require "support/hammerstone/hammerstone_product_contact_relationships"
# Temporarily create a stored_filters_table to test saved filters 
require "support/hammerstone/stored_filters_table"

module Hammerstone::Refine::Conditions
  describe "Refinements" do
    include HammerstoneContactsFilterTestHelper
    # This is an option condition with the path events.type_id and filter refinement
    # of product filters
    let(:option_condition) {
      OptionCondition.new("event_type_id")
        .with_attribute("hammerstone_events.hammerstone_type_id")
        .with_options(
          [{id: "1", display: "Viewed"}, {
            id: "2",
            display: "Purchased"
          }]
        )
        .refine_by_filter(
          FilterCondition.new("hammerstone_events.hammerstone_product._fake")
          .with_scope(Hammerstone::Refine::StoredFilter.where(workspace_id: 2).where(filter_type: "HammerstoneProductsFilter"))
        )
    }

    around do |test|
      ActiveRecord::Base.connection.execute("CREATE TABLE hammerstone_contacts (id bigint primary key);")
      ActiveRecord::Base.connection.execute("CREATE TABLE hammerstone_products (id bigint primary key, hammerstone_contact_id bigint);")
      ActiveRecord::Base.connection.execute("CREATE TABLE hammerstone_types (id bigint primary key);")
      ActiveRecord::Base.connection.execute("CREATE TABLE hammerstone_events (id bigint primary key, hammerstone_contact_id bigint, hammerstone_type_id bigint, hammerstone_product_id bigint);")
      CreateStoredFiltersTable.new.up
      test.call
      CreateStoredFiltersTable.new.down
      ActiveRecord::Base.connection.execute("DROP TABLE hammerstone_contacts, hammerstone_products, hammerstone_types, hammerstone_events;")
    end

    describe "Filter Refinement" do
      it "works" do
        # Use the full Hammerstone::Refine namespace for stabilizers for test environment 
        ENV['NAMESPACE_REFINE_STABILIZERS'] = 1
        state = {"type" => "HammerstoneProductsFilter", "blueprint" => [{"depth" => 1, "type" => "criterion", "condition_id" => "name", "input" => {"clause" => "eq", "value" => "AwesomeCourse"}, "position" => 0}]}.to_json.to_s
        Hammerstone::Refine::StoredFilter.destroy_all
        Hammerstone::Refine::StoredFilter.create(name: "A filter of an awesome product", state: state, id: 2, workspace_id: 2)
        expected_sql = <<~SQL.squish
          SELECT
            `hammerstone_contacts`.*
          FROM
            `hammerstone_contacts`
          WHERE (`hammerstone_contacts`.`id` IN (SELECT
                `hammerstone_events`.`hammerstone_contact_id` FROM `hammerstone_events`
              WHERE (`hammerstone_events`.`hammerstone_type_id` = 2)
              AND `hammerstone_events`.`hammerstone_product_id` IN (SELECT
                  `hammerstone_products`.`id` FROM `hammerstone_products`
                WHERE (`hammerstone_products`.`name` = 'AwesomeCourse'))))
        SQL

        query = apply_condition_on_test_filter(option_condition, {
          clause: OptionCondition::CLAUSE_EQUALS,
          selected: ["2"],
          filter_refinement: {
            clause: FilterCondition::CLAUSE_IN,
            selected: ["2"]
          }
        }, HammerstoneContact.all, HammerstoneContact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end
    end
  end
end

