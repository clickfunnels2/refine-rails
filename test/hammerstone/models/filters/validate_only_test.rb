require "test_helper"
require "support/hammerstone/filter_test_helper"

describe Hammerstone::Refine::Filter do
  describe "Validate only" do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (text_test varchar(256));")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    it "throws an error if no initial query is sent in but can still validate" do
      condition = Hammerstone::Refine::Conditions::TextCondition.new("text_test")
      data = {clause: "eq", value: nil}
      filter = create_filter_nil_initial_query(condition, data)
      exception = assert_raises(Exception) { filter.get_query }
      assert_equal(exception.message, "Initial query must exist")
      filter.validate_only
      assert_equal(["A value is required for clause with id eq"], filter.errors.full_messages)
    end
  end
end
