require "test_helper"

class TestDouble; end
class TestDoublesFilter < Refine::Filter; end

module Namespaced; end
class Namespaced::TestDouble; end
class Namespaced::TestDoublesFilter < Refine::Filter; end


class Refine::FilterTest < ActiveSupport::TestCase
  test "#model with unnamespaced filter" do
    assert_equal TestDouble, TestDoublesFilter.new.model
  end

  test "#model with namespaced filter" do
    assert_equal Namespaced::TestDouble, Namespaced::TestDoublesFilter.new.model
  end
end
