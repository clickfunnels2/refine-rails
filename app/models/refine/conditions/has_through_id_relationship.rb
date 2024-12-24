module Refine::Conditions::HasThroughIdRelationship
  def through_id_relationship
    @through_id_relationship ||= false
  end

  def with_through_id_relationship
    @through_id_relationship = true
    self
  end
end
