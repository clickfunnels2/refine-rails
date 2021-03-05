module Hammerstone::Refine::Conditions
  class Clause
    include HasMeta

    attr_reader :id, :display

    def initialize(id=nil, display=nil)
      @id = id
      @display = display
      @rules
      @messages
    end

    def rules(rules, messages)
      @rules = rules
      @messages = messages
      self
    end

    def requires_inputs(fields)
      #TODO
      self
    end

    def to_array
      {
        id: @id,
        display: @display,
        meta: @meta
      }
    end
  end
end