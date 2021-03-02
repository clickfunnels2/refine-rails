module Hammerstone::Refine::Conditions
  class Condition
    include ActiveModel::Validations
    include HasClauses

    # Add validations for conditions
    validates :id, presence: true

    attr_reader :id, :attribute

    def initialize(id=nil, display=nil)
      @display = display || id.humanize(keep_id_suffix: true).titleize
      @id = id
      @attribute = id
      boot #Allow each condition to set state post initialization
    end

    def with_display(value)
      @display = value
      return self
    end

    #Move to has attributes concern
    def with_attribute(value)
      @attribute = value
      self
    end

    def ensure_attribute_configured
      if @attribute.nil?
        errors.add(:condition, "An attribute is required.")
      end
    end

    #Boot the traits first, so any extended conditions
    #can override the traits if they need to.
    def boot_traits
      #?
    end

    def boot
    end

    def add_rules(rules, messages)
      # rules = merge in the new rule to the rules array?
      # add_messages(messages)
    end

    def add_messages(messages)
      # messages = merge the message into the messages array
    end

    def apply(relation, input)
      #Run all the ensurance validations here
      apply_condition
    end

    def component
      raise NotImplementedError
    end

    def apply_condition
      raise NotImplementedError
    end

    def to_array
      { id: id,
        component: component,
        display: @display,
        meta: ''
      }
    end
  end
end