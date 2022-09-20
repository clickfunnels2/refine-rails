module Hammerstone
  module RefineHelper
    def filter_title
      return t("global.buttons.filter") if @stored_filter.nil?

      @stored_filter.name
    end

    def show_delete_button?
      # don't show the delete button if there is only one group and only one criterion
      # in the group
      true
    end

    def filter_class_name
      @form.configuration[:class_name]
    end

    def conditions
      @form.available_conditions_attributes
    end

    def categories
      categories = conditions.map do |condition|
        condition[:meta][:category]
      end

      categories.uniq.compact
    end

    def conditions_for_category(category)
      conditions.filter do |condition|
        condition[:meta][:category] == category
      end
    end

    def uncategorized_conditions
      conditions.filter { |condition| condition[:meta][:category].nil? }
    end

    def stable_id
      @form.configuration[:stable_id]
    end
  end
end
