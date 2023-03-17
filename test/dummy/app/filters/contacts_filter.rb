class ContactsFilter < Hammerstone::Refine::Filter
  include Hammerstone::Refine::Conditions

  # URL encode/decode the stable_id in the URL
  @@default_stabilizer = Hammerstone::Refine::Stabilizers::UrlEncodedStabilizer

  # @return [ActiveRecord::Relation] initial_query
  def initial_query
    Contact.all
  end

  # @return [Arel::Table] table
  def table
    Contact.arel_table
  end

  # @return [Array<Condition>] conditions
  def conditions
    [
      NumericCondition.new("id"),
      TextCondition.new("name"),
      DateCondition.new("created_at")
    ]
  end
end
