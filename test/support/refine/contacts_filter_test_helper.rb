# Isolate option condition because data types were bleeding across tests
require "support/refine/blank_test_filter"

module ContactsFilterTestHelper
  def apply_condition_on_test_filter(condition, input, query = nil, table = nil)
    blueprint = Refine::Blueprints::Blueprint.new.criterion(condition.id, input)
    table ||= RefineContact.arel_table
    filter = BlankTestFilter.new(blueprint, query || RefineContact.all, [condition], table)
    filter.get_query
  end
end
