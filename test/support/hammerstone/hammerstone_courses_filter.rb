class HammerstoneCoursesFilter < ApplicationFilter
  def automatically_stabilize?
    true
  end

  # TODO revisit the test using this
  def initial_query
    @intial_query || HammerstoneCourse.all
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
