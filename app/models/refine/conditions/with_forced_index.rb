module Refine::Conditions::WithForcedIndex
  def forced_index
    @forced_index ||= nil
  end

  def with_forced_index(index_string)
    @forced_index = index_string
    self
  end
end
