class Refine::Inline::Criteria::DateRefinement
  include ActiveModel::Model

  attr_accessor :clause, :date1, :date2, :days

  def attributes
    {
      clause: clause,
      date1: date1,
      date2: date2,
      days: days
    }.compact
  end
end
