require "test_helper"
require "support/hammerstone/filter_test_helper"
require "support/hammerstone/test_double_filter"
require "support/hammerstone/stored_filters_table"
require "support/hammerstone/stabilize_filter"

module Hammerstone::Refine::Stabilizers
  include FilterTestHelper
  describe "Database Stabilizers" do
    around do |test|
      CreateStoredFiltersTable.new.up
      ApplicationRecord.connection.execute("CREATE TABLE t (text_test varchar(256));")
      test.call
      CreateStoredFiltersTable.new.down
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end
    it "stabilizes and can be reconstructed" do
      builder = Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("id_1",
          clause: Hammerstone::Refine::Conditions::BooleanCondition::CLAUSE_TRUE)
        .and
        .criterion("id_2",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_STARTS_WITH,
          value: "inthesun")

      filter = StabilizeFilter.new(builder)

      assert_equal StoredFilter.count, 0
      state = filter.state
      filter_id = DatabaseStabilizer.new.to_stable_id(filter: filter)

      reconstructed_filter = DatabaseStabilizer.new.from_stable_id(id: filter_id)

      assert_equal state, reconstructed_filter.state
      assert_equal 1, StoredFilter.count
      assert_equal filter.get_query.to_sql, reconstructed_filter.get_query.to_sql
    end
  end
end
