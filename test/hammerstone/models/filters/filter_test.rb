require "test_helper"

class TestDouble; end
class TestDoublesFilter < Hammerstone::Refine::Filter; end

module Namespaced; end
class Namespaced::TestDouble; end
class Namespaced::TestDoublesFilter < Hammerstone::Refine::Filter; end


class Hammerstone::Refine::FilterTest < ActiveSupport::TestCase
  test "#model with unnamespaced filter" do
    assert_equal TestDouble, TestDoublesFilter.new.model
  end

  test "#model with namespaced filter" do
    assert_equal Namespaced::TestDouble, Namespaced::TestDoublesFilter.new.model
  end
end
