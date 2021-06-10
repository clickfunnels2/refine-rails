class TestFilterWithMeta < Hammerstone::Refine::Filter
  def initial_query
    Scaffolding::CompletelyConcrete::TangibleThing.all
  end

  def t(key, options = {})
    I18n.t("scaffolding/completely_concrete/t#{key}", options)
  end

  def conditions
    # Fully configured condition that can define it's own attribute
    # I already have the object called text_field_value. This already has all the data
    # Look in conditions array and get the condition that has already been created. Should match id

    # By default, when you construct a condition that uses attributes, the attribute is optimistically set to the same value as the id.

    [ # most basic implementation
      Hammerstone::Refine::Conditions::TextCondition.new("text_field_value").with_meta({hint: "password"})
      # Hammerstone::Refine::Conditions::TextCondition.new('button_value')
    ]
  end
end
