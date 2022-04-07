class TestFilterWithFilterRefinements < ApplicationFilter
  def automatically_stabilize?
    true
  end

  def table
    HammerstoneContact.arel_table
  end

  def conditions
    [
      Hammerstone::Refine::Conditions::TextCondition.new("email_address"),
      # Has viewed a product named red
      Hammerstone::Refine::Conditions::TextCondition.new("Name").with_attribute("name"),

      Hammerstone::Refine::Conditions::FilterCondition.new("products"),

      FilterCondition.new("products")
        .with_filter("ProductsFilter")
        .with_scope(StoredFilters.where(workspace_id: Current.workspace.id))
        .stored_only,

      # Hammerstone::Refine::Conditions::OptionCondition.new("Has")
      #   .with_nil_option("null")
      #   .with_options(
      #     [{id: "1", display: "Viewed"}, {
      #       id: "2",
      #       display: "Emailed"
      #     }]
      #   )
      #   .with_attribute("hammerstone_venues.hammerstone_events.hammerstone_types.value")
      #   .with_nested_filters(relationship: "hammerstone_venues.hammerstone_events.hammerstone_course.filter")
    ]
  end
end
