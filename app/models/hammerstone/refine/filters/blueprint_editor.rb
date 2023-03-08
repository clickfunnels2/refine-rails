class Hammerstone::Refine::Filters::BlueprintEditor
  # Editor that will transform a given blueprint IN PLACE
  # Designed to support operations for the v2 inline filter builder
  # TODO add support for OR and groups

  attr_reader :blueprint

  def initialize(blueprint)
    @blueprint = blueprint
  end

  # add a criteria at the specified position (defaults to the end)
  def add_criterion(position: -1, conjunction: "and", criterion:)
    # TODO support multiple input conditions, refinements, etc

    conjunction_depth = case conjunction
    in "and" then 1
    in "or" then 0
    end

    # extract local variables from criterion with pattern matching
    criterion => {
      condition_id:,
      input: {
        clause:,
        value:
      }
    }

    nodes_to_insert = []
    nodes_to_insert << {
      depth: conjunction_depth,
      type: "conjunction",
      word: conjunction,
    } if blueprint[position]

    nodes_to_insert << {
      depth: 1,
      type: "criterion",
      condition_id:,
      input: {
        clause:,
        value:
      }
    }

    blueprint.insert position, *nodes_to_insert
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
    # TODO handle groups
    if index == 0
      # TODO remove succeeding conjunction
      blueprint.slice!(index)
    else
      # remove preceding conjunction
      # TODO handle groups
      blueprint.slice!((index - 1)..index)
    end
  end
end
