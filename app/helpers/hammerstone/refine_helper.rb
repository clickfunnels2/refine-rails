module Hammerstone
  module RefineHelper
    def filter_title
      return t("global.buttons.filter") if @stored_filter.nil?

      @stored_filter.name
    end

    def show_delete_button?
      # don't show the delete button if there is only one group and only one criterion
      # in the group
      return true unless @form.grouped_criteria.length == 1 && @form.grouped_criteria.first.length == 1

      false
    end

    def filter_class_name
      @refine_filter.configuration[:class_name]
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

    def id_suffix
      @id_suffix
    end

    def create_id(value)
      "#{value}_#{id_suffix}"
    end
  end
end
