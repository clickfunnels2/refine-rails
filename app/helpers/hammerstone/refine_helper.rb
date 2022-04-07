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

    def filter_title
      return t("global.buttons.filter") if @stored_filter.nil?

      @stored_filter.name
    end

    def show_delete_button?
      # don't show the delete button if there is only one group and only one criterion
      # in the group
      return true unless grouped_blueprint.length == 1 && grouped_blueprint.first.length == 1

      false
    end

    def filter_class_name
      @refine_filter.configuration[:class_name]
    end

    def condition_for_criterion(criterion)
      conditions.find { |condition| condition[:id] == criterion[:condition_id] }
    end

    def meta_for_criterion(criterion)
      condition = condition_for_criterion criterion
      meta_for_condition(condition)
    end

    def meta_for_condition(condition)
      condition[:meta]
    end

    def meta_for_refinement_clause(condition, criterion)
      condition_meta = meta_for_condition(condition)
      # condition[:id] is the refinement such as date_refinement, condition_refinement
      selected_clause_id = criterion[:input][condition[:id].to_sym][:clause]
      clauses = condition_meta[:clauses]
      selected_clause = clauses.find { |clause| clause[:id] == selected_clause_id }
      selected_clause[:meta]
    end

    def meta_for_clause(criterion)
      meta = meta_for_criterion(criterion)
      selected_clause_id = criterion[:input][:clause]
      clauses = meta[:clauses]
      selected_clause = clauses.find { |clause| clause[:id] == selected_clause_id }
      selected_clause[:meta]
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
