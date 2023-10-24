class CoursesFilter < Refine::Filter
  def automatically_stabilize?
    true
  end

  # TODO revisit the test using this
  def initial_query
    @intial_query || RefineCourse.all
  end

  def t(key, options = {})
    key
  end

  def table
    RefineCourse.arel_table
  end

  def conditions
    [
      # 🚅 super scaffolding will insert new fields above this line.
      TextCondition.new("name"),
    ]
  end
end
