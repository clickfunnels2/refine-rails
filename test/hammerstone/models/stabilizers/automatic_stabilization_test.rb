require "test_helper"
require "support/hammerstone/stored_filters_table"
require "support/hammerstone/automatic_stabilization_test_filter"

module Hammerstone::Refine::Stabilizers
  include FilterTestHelper

  describe "Automatic Stabilization Test" do
    it "stabilizes when default stable id is used" do
      AutomaticStabilizationTestFilter.default_stable_id_generator(UrlEncodedStabilizer)
      builder = Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("id_1",
          clause: Hammerstone::Refine::Conditions::BooleanCondition::CLAUSE_TRUE)
        .and
        .criterion("id_2",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_STARTS_WITH,
          value: "inthesun")
      filter = AutomaticStabilizationTestFilter.new(builder)
      assert !filter.configuration[:stable_id].nil?, "Expect stable_id to not be nil"
    end

    it "can use a different stabilizer" do
      AutomaticStabilizationUrlFilter.default_stable_id_generator(DatabaseStabilizer)
      filter = AutomaticStabilizationUrlFilter.new(["blue"])
      id = filter.configuration[:stable_id]
      filter = UrlEncodedStabilizer.new.from_stable_id(id: id)
      assert_equal ["blue"], filter.blueprint
    end

    it "throws error if automatic stabilization is true but nothing set" do
      filter = AutomaticStabilizationTestFilter.new
      AutomaticStabilizationTestFilter.default_stabilizer = nil
      exception =
        assert_raises ArgumentError do
          filter.configuration
        end
      assert_equal "No stable id class set. Set using the default_stable_id_generator method", exception.message
    end
  end

  class AutomaticStabilizationUrlFilter < AutomaticStabilizationTestFilter
    def automatic_stable_id_generator
      UrlEncodedStabilizer
    end
  end
end
