require "support/hammerstone/filter_test_helper"

class TestDoubleFilter < Hammerstone::Refine::Filter
  # Overwrite conditions as necessary for testing
  attr_accessor :conditions

  def initial_query
    FilterTestHelper::TestDouble.all
  end

  def t(key, options = {})
    I18n.t("scaffolding/completely_concrete/tangible_things#{key}", options)
  end

  def table
    FilterTestHelper::TestDouble.arel_table
  end
end
