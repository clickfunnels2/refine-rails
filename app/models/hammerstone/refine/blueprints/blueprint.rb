module Hammerstone::Refine::Blueprints
  class Blueprint

    def initialize
      @blueprint = []
      @depth = 0
      @word
    end

    def criterion(condition_id, input)
      if !@blueprint.blank? && @blueprint.last[:type] == 'criterion'
        conjunction
      end

      add({
          type: 'criterion',
          condition_id: condition_id,
          depth: @depth,
          input: input
        })
      #To chain methods need to return self, not the value from add
      self
    end

    def conjunction
      add({
        type: 'conjunction',
        word: @word,
        depth: @depth
      })
    end

    def and
      @word = 'and'
      self
    end

    def or
      @word = 'or'
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
