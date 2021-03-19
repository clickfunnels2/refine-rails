module Hammerstone::Refine::Blueprints
  class Blueprint

    def initialize
      @blueprint = []
      @depth = 0
    end

    def group(&block)
      @depth = @depth+=1
      instance_eval(&block)
      @depth = @depth-=1
      self
    end

    def criterion(condition_id, input)
      if !@blueprint.blank? && @blueprint.last[:type] == 'criterion'
        raise 'Conjunction missing'
      end

      add({
          type: 'criterion',
          condition_id: condition_id,
          depth: @depth,
          input: input
        })
      self
    end

    def conjunction(word)
      add({
        type: 'conjunction',
        word: word,
        depth: @depth
      })
    end

    def and
      conjunction('and')
      self
    end

    def or
      conjunction('or')
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
