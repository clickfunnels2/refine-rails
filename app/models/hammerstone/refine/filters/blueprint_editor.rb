class Hammerstone::Refine::Filters::BlueprintEditor
  # Editor that will transform a given blueprint IN PLACE
  # TODO add support for OR and groups

  attr_reader :blueprint

  def initialize(blueprint)
    @blueprint = blueprint
  end

  # append a clause to the end of the blueprint
  def append(criterion)
    # TODO support multiple input conditions, refinements, etc
    criterion => {
      condition_id:,
      input: {
        clause:,
        value:
      }
    }

    blueprint << {
      depth: 0,
      type: "conjunction",
      word: "and",
      uid: blueprint.length,
      position: blueprint.length
    } unless blueprint.empty?

    blueprint << {
      depth: 0,
      type: "criterion",
      condition_id:,
      uid: blueprint.length,
      position: blueprint.length,
      input: {
        clause:,
        value:
      }
    }
  end

  def update(index, criterion)
    criterion => {
      input: {
        clause:,
        value:
      }
    }

    blueprint[index][:input][:clause] = clause
    blueprint[index][:input][:value] = value
  end

  def delete(index)
    if index == 0
      blueprint.slice!(index)
    else
      # remove preceding conjunction
      blueprint.slice!((index - 1)..index)
    end
  end


end