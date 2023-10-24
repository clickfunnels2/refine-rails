class TestFilterWithFilterRefinements < Refine::Filter
  def automatically_stabilize?
    true
  end

  def table
    Contact.arel_table
  end

  def conditions
    [
      Refine::Conditions::TextCondition.new("email_address"),
      # Has viewed a product named red
      Refine::Conditions::TextCondition.new("Name").with_attribute("name"),

      Refine::Conditions::FilterCondition.new("products"),

      FilterCondition.new("products")
        .with_filter("ProductsFilter")
        .with_scope(StoredFilters.where(workspace_id: Current.workspace.id))
        .stored_only,

      # Refine::Conditions::OptionCondition.new("Has")
      #   .with_nil_option("null")
      #   .with_options(
      #     [{id: "1", display: "Viewed"}, {
      #       id: "2",
      #       display: "Emailed"
      #     }]
      #   )
      #   .with_attribute("refine_venues.refine_events.refine_types.value")
      #   .with_nested_filters(relationship: "refine_venues.refine_events.refine_course.filter")
    ]
  end
end
