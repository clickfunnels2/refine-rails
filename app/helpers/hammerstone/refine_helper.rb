module Hammerstone
  module RefineHelper
    def condition_for_criterion(criterion, conditions)
      conditions.find { |condition| condition[:id] == criterion[:condition_id] }
    end

    def meta_for_criterion(criterion, conditions)
      condition = condition_for_criterion criterion, conditions
      condition[:meta]
    end

    def clause_for_criterion(criterion, conditions)
      condition = condition_for_criterion criterion, conditions
      condition[:component].underscore
    end
  end
end
