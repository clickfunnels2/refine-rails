# Isolate option condition because data types were bleeding across tests
require "support/hammerstone/blank_test_filter"

module HammerstoneContactsFilterTestHelper
  def apply_condition_on_test_filter(condition, input, query = nil, table = nil)
    blueprint = Hammerstone::Refine::Blueprints::Blueprint.new.criterion(condition.id, input)
    table ||= HammerstoneContact.arel_table
    filter = BlankTestFilter.new(blueprint, query || HammerstoneContact.all, [condition], table)
    filter.get_query
  end
end
