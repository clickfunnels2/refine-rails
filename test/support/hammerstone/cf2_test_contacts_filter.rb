class Cf2TestContactsFilter < ApplicationFilter
  def automatically_stabilize?
    true
  end

  def table
    Contact.arel_table
  end

  def conditions
    [
      Hammerstone::Refine::Conditions::TextCondition.new("email_address"),
      # Has viewed a product named red
      Hammerstone::Refine::Conditions::TextCondition.new("Name").with_attribute("name"),
      Hammerstone::Refine::Conditions::TextCondition.new("Has viewed or purchased a course with title").with_attribute("events.type.courses.title"),
      Hammerstone::Refine::Conditions::OptionCondition.new("Filter Refinement")
        .with_options(
          [{id: "1", display: "Viewed"}, {
            id: "2",
            display: "Purchased"
          }]
        )
        .with_attribute("events.type_id")
        .with_filter_refinement(filter_class: ProductsFilter, attribute: events.product, scope: ProductsFilter.all),
      # Needs to be a filter condition

      Hammerstone::Refine::Conditions::OptionCondition.new("Has")
        .with_nil_option("null")
        .with_options(
          [{id: "1", display: "Viewed"}, {
            id: "2",
            display: "Purchased"
          }]
        )
        .with_attribute("events.type_id")
        .with_nested_filters(relationship: "events.course.filter")
    ]
  end
end
