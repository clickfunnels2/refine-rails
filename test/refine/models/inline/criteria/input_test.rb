require "test_helper"
require "support/refine/test_double_filter"
require "refine/invalid_filter_error"

describe Refine::Inline::Criteria::Input do
  describe "strip_values" do  
    it "strips leading and trailing whitespace from all string values" do
      input = Refine::Inline::Criteria::Input.new({"value" => "  value  ", "value1" => "  value1", "value2" => "value2  "})
      input.strip_values
      assert_equal({value: "value", value1: "value1", value2: "value2"}, input.attributes.slice(:value, :value1, :value2))
    end
  end
end