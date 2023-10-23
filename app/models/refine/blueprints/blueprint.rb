module Refine::Blueprints
  class Blueprint
    # DSL-based model for building filter blueprints
    attr_reader :blueprint

    def initialize
      @blueprint = []
      @depth = 0
    end

    def group(&block)
      @depth = @depth += 1
      instance_eval(&block)
      @depth = @depth -= 1
      self
    end

    def criterion(condition_id, input)
      if !@blueprint.blank? && @blueprint.last[:type] == "criterion"
        raise "Conjunction missing"
      end

      add({
        depth: @depth,
        type: "criterion",
        condition_id: condition_id,
        input: input,
      })
      self
    end

    def conjunction(word)
      add({
        depth: @depth,
        type: "conjunction",
        word: word
      })
    end

    def and
      conjunction("and")
      self
    end

    def or
      conjunction("or")
      self
    end

    def add(item)
      @blueprint.append(item)
    end

    def to_array
      @blueprint
    end
  end
end
