require "support/hammerstone/blank_test_filter"

module FilterTestHelper
  class TestDouble < ActiveRecord::Base
    self.table_name = "t"
  end

  def apply_condition_on_test_filter(condition, input, query = nil, table = nil)
    blueprint = Hammerstone::Refine::Blueprints::Blueprint.new.criterion(condition.id, input)
    table ||= TestDouble.arel_table
    filter = BlankTestFilter.new(blueprint, query || TestDouble.all, [condition], table)
    filter.get_query
  end

  def apply_condition_and_return_filter(condition, input, query = nil, table = nil)
    blueprint = Hammerstone::Refine::Blueprints::Blueprint.new.criterion(condition.id, input)
    table ||= TestDouble.arel_table
    filter = BlankTestFilter.new(blueprint, query || TestDouble.all, [condition], table)
    filter.get_query
    filter
  end
end
