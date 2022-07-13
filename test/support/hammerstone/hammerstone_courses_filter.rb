class HammerstoneCoursesFilter < Hammerstone::Refine::Filter
  def automatically_stabilize?
    true
  end

  # TODO revisit the test using this
  def initial_query
    @intial_query || HammerstoneCourse.all
  end

  def t(key, options = {})
    key
  end

  def table
    HammerstoneCourse.arel_table
  end

  def conditions
    [
      # 🚅 super scaffolding will insert new fields above this line.
      TextCondition.new("name"),
    ]
  end
end
