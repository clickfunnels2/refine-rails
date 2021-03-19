module Hammerstone::Refine::Conditions

  class Condition
    include ActiveModel::Validations

    #TODO remove hasclauses here, rename boot_has_clauses
    include HasClauses
    include HasMeta

    validate :ensure_id
    validate :ensure_attribute_configured

    attr_reader :id, :attribute

    def initialize(id=nil, display=nil)
      @display = display || id.humanize(keep_id_suffix: true).titleize if id
      @id = id
      @attribute = id
      @rules = {}
      boot_has_clauses #Interpolate later in life for each class that needs it
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
        errors.add(:base, "An attribute is required.")
      end
    end
    #End attributes concern

    def ensure_id
      if @id.nil?
        errors.add(:base, "Every condition must have an ID")
      end
    end

    #Boot the traits first, so any extended conditions
    #can override the traits if they need to.
    def boot_traits
      #?
    end

    def boot
    end

    def add_rules(new_rules)
      #TODO add messages if desired
      @rules.merge!(new_rules)
      self
    end

    def add_messages(messages)
      # messages = merge the message into the messages array if we go this route
    end

    def apply(input, table)
      #Run all the ensurance validations here - developer configured correctly
      validate_user_input(input)
      apply_condition(input, table)
    end

    def validate_user_input(input)
      add_clause_rules_to_condition(input)
      if !clause_exists?(input)
        errors.add(:base, "The clause with id #{input[:clause]} was not found")
        raise Errors::ConditionClauseError, "#{errors.full_messages}"
      end
      validate_condition(input)
    end

    def clause_exists?(input)
      current_clause = clauses.select{ |clause| clause.id == input[:clause] }
      current_clause.present?
    end

    def validate_condition(input)
      @rules = recursively_evaluate_lazy_enumerable(@rules)

      @rules.each_pair do |k,v|
        if input[k].blank?
          errors.add(:base, "A #{k} is required for clause with id #{input[:clause]}")
          raise Errors::ConditionClauseError, "#{errors.full_messages}"
        end
      end
    end

    def component
      raise NotImplementedError
    end

    def apply_condition
      raise NotImplementedError
    end

    def to_array
      #has clauses has already been called, so meta is populated with possible closures
      if valid?
        {
          id: id,
          component: component,
          display: @display,
          meta: evaluated_meta
        }
      else
        raise ConditionError, "#{errors.full_messages}"
      end
    end

    def evaluated_meta
      recursively_evaluate_lazy_enumerable(@meta)
    end

    def call_proc_if_callable(value)
      if value.respond_to? :call
        value.call
      else
        value
      end
    end

    #In HasCallbacks

    def recursively_evaluate_lazy_enumerable(enumerable)
      if enumerable.is_a? Hash
        enumerable.transform_values! do |value|
          update_value(value)
        end
      elsif enumerable.is_a? Array
        enumerable.map! do |value|
          update_value(value)
        end
      end
    end

    def update_value(value)
      value = call_proc_if_callable(value)
      if value.respond_to? :to_array
        value = value.to_array
      end
      if value.is_a? Enumerable
        recursively_evaluate_lazy_enumerable(value)
      end
      value
    end
  end
end