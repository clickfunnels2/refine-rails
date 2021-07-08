require "support/hammerstone/filter_test_helper"

class BtStabilizeFilter < ApplicationFilter
  # Hard code this filter to mimic an application. Necessary for filter rebuilding when restoring from stable_id

  def automatically_stabilize?
    true
  end

  def t(key, options = {})
    I18n.t("scaffolding/completely_concrete/tangible_things#{key}", options)
  end

  def table
    FilterTestHelper::TestDouble.arel_table
  end

  def conditions
    [
      Hammerstone::Refine::Conditions::BooleanCondition.new("id_1").only_clauses([Hammerstone::Refine::Conditions::BooleanCondition::CLAUSE_TRUE]),
      Hammerstone::Refine::Conditions::TextCondition.new("id_2").only_clauses([Hammerstone::Refine::Conditions::TextCondition::CLAUSE_STARTS_WITH])
    ]
  end
end
