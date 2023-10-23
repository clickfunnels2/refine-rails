# This test is replaced by the custom database stabilizer in services, but will
# be present in the final gem. The client repo requires a workspace_id on the stored filters
# table.
# require "test_helper"
# require "support/refine/stored_filters_table"
# require "support/refine/stabilize_filter"

# module Refine::Stabilizers
#   include FilterTestHelper
#   describe "Database Stabilizers" do
#     around do |test|
#       ApplicationRecord.connection.execute("CREATE TABLE t (text_test varchar(256));")
#       test.call
#       ApplicationRecord.connection.execute("DROP TABLE t;")
#     end
#     it "stabilizes and can be reconstructed" do
#       builder = Refine::Blueprints::Blueprint.new
#         .criterion("id_1",
#           clause: Refine::Conditions::BooleanCondition::CLAUSE_TRUE)
#         .and
#         .criterion("id_2",
#           clause: Refine::Conditions::TextCondition::CLAUSE_STARTS_WITH,
#           value: "inthesun")

#       filter = StabilizeFilter.new(builder)
#       state = filter.state
#       assert_difference "Refine::StoredFilter.count", 1 do
#         filter_id = DatabaseStabilizer.new.to_stable_id(filter: filter)
#         reconstructed_filter = DatabaseStabilizer.new.from_stable_id(id: filter_id)
#         assert_equal state, reconstructed_filter.state
#         assert_equal filter.get_query.to_sql, reconstructed_filter.get_query.to_sql
#       end
#     end
#   end
# end
