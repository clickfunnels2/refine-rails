class BlankTestFilter < Hammerstone::Refine::Filter
  attr_reader :initial_query
  attr_accessor :conditions

  def t(key, options = {})
    I18n.t("scaffolding/completely_concrete/t#{key}", options)
  end

  def initialize(blueprint = nil, initial_query = nil, conditions = nil, table = nil)
    @initial_query = initial_query || Scaffolding::CompletelyConcrete::TangibleThing.all
    @table = table
    @conditions = conditions
    super(blueprint)
  end

  attr_reader :table
end
