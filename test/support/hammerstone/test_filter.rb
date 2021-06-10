class TestFilter < Hammerstone::Refine::Filter
  # Overwrite conditions as necessary for testing
  attr_accessor :conditions

  def initial_query
    Scaffolding::CompletelyConcrete::TangibleThing.all
  end

  def t(key, options = {})
    I18n.t("scaffolding/completely_concrete/tangible_things#{key}", options)
  end

  # def conditions
  #   #By default, when you construct a condition that uses attributes, the attribute is optimistically set to the same value as the id.

  #   [ #most basic implementation
  #     Hammerstone::Refine::Conditions::TextCondition.new('text_field_value')
  #     # Hammerstone::Refine::Conditions::TextCondition.new('button_value')
  #   ]
  # end

  def table
    Scaffolding::CompletelyConcrete::TangibleThing.arel_table
  end
end
