module Hammerstone
  module RefineHelper
    def grouped_blueprint
      new_blueprint = []

      # start with an empty group
      new_blueprint.push []

      blueprint.each_with_index do |piece, index|
        if piece[:word] == "or"
          new_blueprint.push []
        elsif piece[:word] == "and"
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

    def categories
      categories = conditions.map do |condition|
        condition[:meta][:category]
      end

      categories.uniq.compact
    end

    def conditions
      configuration[:conditions]
    end

    def conditions_for_category(category)
      conditions.filter do |condition|
        condition[:meta][:category] == category
      end
    end

    def uncategorized_conditions
      conditions.filter { |condition| condition[:meta][:category].nil? }
    end

    def blueprint
      first_condition = conditions[0]
      meta = first_condition[:meta]

      unless @refine_filter.blueprint&.any?
        return [{
          depth: 1,
          type: "criterion",
          condition_id: first_condition[:id],
          input: {clause: meta[:clauses][0][:id]},
        }]
      end

      @refine_filter.blueprint
    end

    def configuration
      @refine_filter.configuration
    end

    def stable_id
      configuration[:stable_id]
    end
  end
end
