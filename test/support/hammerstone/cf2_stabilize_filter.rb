class Cf2StabilizeFilter < ApplicationFilter
  def automatically_stabilize?
    true
  end

  def t(key, options = {})
    I18n.t("scaffolding/completely_concrete/tangible_things#{key}", options)
  end

  def table
    Scaffolding::CompletelyConcrete::TangibleThing.arel_table
  end

  def conditions
    [
      Hammerstone::Refine::Conditions::TextCondition.new("button_value").only_clauses([Hammerstone::Refine::Conditions::TextCondition::CLAUSE_SET]),
      Hammerstone::Refine::Conditions::TextCondition.new("text_field_value").only_clauses([Hammerstone::Refine::Conditions::TextCondition::CLAUSE_STARTS_WITH])
    ]
  end
end
