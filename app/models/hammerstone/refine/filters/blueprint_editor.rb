class Hammerstone::Refine::Filters::BlueprintEditor
  # Editor that will transform a given blueprint IN PLACE
  # Designed to support operations for the v2 inline filter builder via ConditionsController

  attr_reader :blueprint

  VALUE_ATTRS = %i[
    date1
    date2
    days
    selected
    value
    value1
    value2
  ].freeze

  def initialize(blueprint)
    @blueprint = blueprint
  end

  # add a criteria at the specified position (defaults to the end)
  def add(position: -1, conjunction: "and", criterion:)
    # TODO support multiple input conditions, refinements, etc

    conjunction_depth = case conjunction
    in "and" then 1
    in "or" then 0
    end

    # extract data from criterion
    condition_id = criterion[:condition_id]
    input = criterion[:input].slice(*VALUE_ATTRS)
    input[:clause] = criterion[:input][:clause]

    nodes_to_insert = []
    nodes_to_insert << {
      depth: conjunction_depth,
      type: "conjunction",
      word: conjunction,
    } if blueprint[(position.negative? ? position + 1 : position - 1)]

    nodes_to_insert << {
      depth: 1,
      type: "criterion",
      condition_id: condition_id,
      input: input
    }

    blueprint.insert position, *nodes_to_insert
  end

  def update(index, criterion:)
    # extract data from criterion
    input = criterion[:input].slice(*VALUE_ATTRS)
    input[:clause] = criterion[:input][:clause]

    blueprint[index][:input] = input
  end

  def delete(index)
   # To support 'groups' there is some complicated logic for deleting criterion.
   #
   # Imagine this simplified blueprint: [eq, and, sw, or, eq]
   #
   # User clicks to delete the last eq. We also have to delete the preceding or
   # otherwise we're left with a hanging empty group
   #
   # What if the user deletes the sw? We have to clean up the preceding and.
   #
   # Imagine another scenario: [eq or sw and ew]
   # Now we delete the first eq but this time we need to clean up the or.
   #
   # These conditionals cover these cases.

    previous_entry = index.zero? ? nil : blueprint[index - 1]
    next_entry = blueprint[index + 1]

    next_is_or = next_entry && next_entry[:word] == 'or'
    previous_is_or = previous_entry && previous_entry[:word] == 'or'

    next_is_right_paren = next_is_or || !next_entry
    previous_is_left_paren = previous_is_or || !previous_entry

    is_first_in_group = previous_is_left_paren && !next_is_right_paren
    is_last_in_group = previous_is_left_paren && next_is_right_paren
    is_last_criterion = !previous_entry && !next_entry

    if is_last_criterion
      blueprint.slice!(index)
    elsif is_last_in_group && previous_is_or
      blueprint.slice!((index - 1)..index)
    elsif is_last_in_group && !previous_entry
      blueprint.slice!(index..(index + 1))
    elsif is_first_in_group
      blueprint.slice!(index..(index + 1))
    else
      blueprint.slice!((index - 1)..index)
    end

  end
end
