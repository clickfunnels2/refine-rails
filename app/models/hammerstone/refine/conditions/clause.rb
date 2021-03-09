module Hammerstone::Refine::Conditions
  class Clause
    include HasMeta

    attr_reader :id, :display, :rules

    def initialize(id=nil, display=nil)
      @id = id
      @display = display
      @rules = {}
      @messages
    end

    # def rules(rules, messages)
    #   @rules = rules
    #   @messages = messages
    #   self
    # end

    def with_rules(user_defined_hash)
      @rules.merge!(user_defined_hash)
      self
    end

    def requires_inputs(fields)
      @rules.merge!({"#{fields}": 'required'})
      self
    end

    def to_array
      {
        id: @id,
        display: @display,
        meta: meta
      }
    end
  end
end