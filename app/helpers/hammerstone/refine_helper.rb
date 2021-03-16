module Hammerstone
  module RefineHelper
    def grouped_blueprint
      return [] unless @refine_filter.blueprint.any?

      new_blueprint = []

      # start with an empty group
      new_blueprint.push []

      @refine_filter.blueprint.each_with_index do |piece, index|
        if piece[:word] == 'or'
          new_blueprint.push []
        elsif piece[:word] == 'and'
          next
        else
          piece[:position] = index
          new_blueprint.last.push piece
        end
      end

      new_blueprint
    end

    def filter_class_name
      @refine_filter.configuration[:class_name]
    end

    def condition_for_criterion(criterion)
      conditions.find { |condition| condition[:id] == criterion[:condition_id] }
    end

    def meta_for_criterion(criterion)
      condition = condition_for_criterion criterion
      condition[:meta]
    end

    def clause_for_criterion(criterion)
      condition = condition_for_criterion criterion
      condition[:component].underscore
    end

    def conditions
      configuration[:conditions]
    end

    def blueprint
      @refine_filter.blueprint
    end

    def configuration
      @refine_filter.configuration
    end
  end
end
