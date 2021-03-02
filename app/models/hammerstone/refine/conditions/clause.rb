module Hammerstone::Refine::Conditions
  class Clause

    def initialize(id=nil, display=nil)
      @id = id
      @display = display
      @rules
      @messages
      @meta = []
    end

    def rules(rules, messages)
      @rules = rules
      @messages = messages
      self
    end

    def requires_input(fields)
      #add to rules it appears
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