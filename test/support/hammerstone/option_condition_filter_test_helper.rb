# Isolate option condition because data types were bleeding across tests
require "support/hammerstone/blank_test_filter"

module OptionConditionFilterTestHelper
  class FakeClass < ActiveRecord::Base
    self.table_name = "o"
  end

  def apply_condition_on_test_filter(condition, input, query = nil, table = nil)
    blueprint = Hammerstone::Refine::Blueprints::Blueprint.new.criterion(condition.id, input)
    table ||= FakeClass.arel_table
    filter = BlankTestFilter.new(blueprint, query || FakeClass.all, [condition], table)
    filter.get_query
  end

  def apply_condition_and_return_filter(condition, input, query = nil, table = nil)
    blueprint = Hammerstone::Refine::Blueprints::Blueprint.new.criterion(condition.id, input)
    table ||= FakeClass.arel_table
    filter = BlankTestFilter.new(blueprint, query || FakeClass.all, [condition], table)
    filter.get_query
    filter
  end
end
