require "support/hammerstone/filter_test_helper"

class BlankTestFilter < Hammerstone::Refine::Filter
  attr_accessor :conditions

  def t(key, options = {})
    I18n.t("#{key}", options)
  end

  def initialize(blueprint = nil, initial_query = FilterTestHelper::TestDouble.all, conditions = nil, table = FilterTestHelper::TestDouble.arel_table)
    @table = table
    @conditions = conditions
    super(blueprint, initial_query)
  end

  attr_reader :table
end
