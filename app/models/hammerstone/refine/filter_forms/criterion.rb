class Hammerstone::Refine::FilterForms::Criterion
  # View model that holds the state of individual criteria within the Filter form
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :depth, :integer
  attribute :criterion, :string
  attribute :condition_id, :string
  attribute :input
  attribute :word, :string
  attribute :type, :string
  attribute :position, :integer
  attribute :uid, :string

  attr_accessor :form

  def filter
    form.filter
  end

  def condition
    @_condition ||= begin
      result = form.conditions.find { |condition| condition.id == condition_id }
      if result
        instantiate_condition(result)
      end
      result.dup
    end
  end

  def condition_attributes
    condition.to_array
  end

  def meta
    condition_attributes[:meta]
  end

  def selected_clause
    input[:clause]
  end

  def selected_clause_meta
    meta[:clauses].find {|c| c[:id] == selected_clause }[:meta]
  end

  def refinements
    condition.refinements_to_array
  end

  private

  def instantiate_condition(condition_class)
    condition_class.set_filter(filter)
    translate_display(condition_class)
    condition_class
  end

  def translate_display(condition)
    # If there are no locale definitions for this condition's subject, we can allow I18n to use a human-readable version of the ID.
    # But, ideally, they have locales defined and we can find one of those.
    label_fallback = {default: condition.id.humanize(keep_id_suffix: true).titleize}
    condition.display ||= I18n.t(
      ".filter.conditions.#{condition.id}.label",
      default: I18n.t(".fields.#{condition.id}.label", **label_fallback)
    )
  end
end
