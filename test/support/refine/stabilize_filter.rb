require "support/refine/filter_test_helper"

class StabilizeFilter < Refine::Filter
  # Hard code this filter to mimic an application. Necessary for filter rebuilding when restoring from stable_id

  def initial_query
    FilterTestHelper::TestDouble.all
  end

  def t(key, options = {})
    I18n.t("scaffolding/completely_concrete/tangible_things#{key}", options)
  end

  def table
    FilterTestHelper::TestDouble.arel_table
  end

  def conditions
    [
      Refine::Conditions::BooleanCondition.new("id_1").only_clauses([Refine::Conditions::BooleanCondition::CLAUSE_TRUE]),
      Refine::Conditions::TextCondition.new("id_2").only_clauses([Refine::Conditions::TextCondition::CLAUSE_STARTS_WITH])
    ]
  end
end
