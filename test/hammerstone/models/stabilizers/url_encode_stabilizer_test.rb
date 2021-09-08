require "test_helper"
require "support/hammerstone/stabilize_filter"

module Hammerstone::Refine::Stabilizers
  include FilterTestHelper
  describe "URL Encode Stabilizers" do
    it "stabilizes and can be reconstructed" do
      builder = Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("id_1",
          clause: Hammerstone::Refine::Conditions::BooleanCondition::CLAUSE_TRUE)
        .and
        .criterion("id_2",
          clause: Hammerstone::Refine::Conditions::TextCondition::CLAUSE_STARTS_WITH,
          value: "foo")

      filter = StabilizeFilter.new(builder)

      state = filter.state

      filter_id = UrlEncodedStabilizer.new.to_stable_id(filter: filter)
      reconstructed_filter = UrlEncodedStabilizer.new.from_stable_id(id: filter_id)
      assert_equal state, reconstructed_filter.state
    end

    it "raises an error if id is blank or nil" do
      assert_raises Hammerstone::Refine::Stabilizers::Errors::UrlStabilizerError do
        UrlEncodedStabilizer.new.from_stable_id(id: nil)
      end
    end
  end
end
