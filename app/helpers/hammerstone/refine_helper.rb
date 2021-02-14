module Hammerstone
  module RefineHelper
    def condition_for_id(condition_id, conditions)
      conditions.find { |condition| condition[:id] == condition_id }
    end
  end
end
