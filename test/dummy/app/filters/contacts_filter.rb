class ContactsFilter < Hammerstone::Refine::Filter
  include Hammerstone::Refine::Conditions
  @@default_stabilizer = Hammerstone::Refine::Stabilizers::UrlEncodedStabilizer

  def initial_query
    Contact.all
  end

  def table
    Contact.arel_table
  end

  def conditions
    [
      NumericCondition.new("id"),
      TextCondition.new("name"),
      DateCondition.new("created_at")
    ]
  end
end
