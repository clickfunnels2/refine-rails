class Cf2BlankTestFilter < ApplicationFilter
  attr_accessor :conditions

  def initialize(blueprint = nil, conditions = nil)
    @conditions = conditions
    super(blueprint)
  end

  def table
    Scaffolding::CompletelyConcrete::TangibleThing.all
  end
end
