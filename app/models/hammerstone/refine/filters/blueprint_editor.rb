class Hammerstone::Refine::Filters::BlueprintEditor
  # Editor that will transform a given blueprint IN PLACE
  # TODO add support for OR and groups

  attr_reader :blueprint

  def initialize(blueprint)
    @blueprint = blueprint
  end

  # add a criteria at the specified position (defaults to the end)
  def add_criterion(position: -1, **criterion)
    # TODO support multiple input conditions, refinements, etc
    depth = blueprint[position]&.[] :depth
    depth ||= 0

    insert_criterion(position: position, depth: depth, conjunction: "and", **criterion)
  end

  def add_or_criterion(position: -1, **criterion)
    # TODO support multiple input conditions, refinements, etc
    depth = blueprint[position]&.[] :depth
    depth ||= 0

    insert_criterion(position: position, depth: depth, conjunction: "or", **criterion)
  end

  def add_group_criterion(position: -1, **criterion)
    # TODO support multiple input conditions, refinements, etc
    depth = blueprint[position]&.[] :depth
    depth ||= 0
    depth += 1

    insert_criterion(position: position, depth: depth, conjunction: "and", **criterion)
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

  private

  def insert_criterion(position:, depth:, conjunction:, **criterion)
    criterion => {
      condition_id:,
      input: {
        clause:,
        value:
      }
    }

    nodes_to_insert = []
    nodes_to_insert << {
      depth: depth,
      type: "conjunction",
      word: conjunction,
    } if blueprint[position]

    nodes_to_insert << {
      depth: depth,
      type: "criterion",
      condition_id:,
      input: {
        clause:,
        value:
      }
    }

    blueprint.insert postion, *inserts
  end


end