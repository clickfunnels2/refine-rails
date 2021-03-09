module Hammerstone::Refine::Conditions

  class Condition
    include ActiveModel::Validations

    #TODO remove hasclauses here, rename boot_has_clauses
    include HasClauses
    include HasMeta

    validate :ensure_id
    validate :ensure_attribute_configured
    # validates_with ConditionsValidator

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
      #TODO add messages
      @rules.merge!(new_rules)
      self
    end

    def add_messages(messages)
      # messages = merge the message into the messages array
    end

    def apply(relation, input)
      #Run all the ensurance validations here (confirm all are run)
      #Called from filter.make_query (rename?)
      validate_clause_allowed(input)
      validate_clause_rules(input)
      apply_condition(relation, input)
    end

    def validate_clause_rules(input)
      current_clause = clauses.select{ |clause| clause.id == input[:clause] }
      #.select returns array of current clause object
      current_clause[0].rules.each_pair do |k, v|
        #TODO add other validations besides required...?
        if input[k].blank?
          errors.add(:base, "The clause with id #{input[:clause]} is required")
          raise Errors::ConditionClauseError, "#{errors.full_messages}"
        end
      end
    end

    def validate_clause_allowed(input)
      frontend_input = input[:clause]
      good_clause = get_clauses.select{|clause| clause[:id]==frontend_input}
      if good_clause.empty?
        errors.add(:base, "The clause with id #{frontend_input} was not found")
        raise Errors::ConditionClauseError, "#{errors.full_messages}"
      end
    end

    def component
      raise NotImplementedError
    end

    def apply_condition
      raise NotImplementedError
    end

    # def to_array
    #   if valid?
    #     { id: id,
    #       component: component,
    #       display: @display,
    #       meta: {
    #         clauses: clauses.map{|clause| clause.to_array}
    #       }
    #     }
    #   else
    #     raise ConditionError, "#{errors.full_messages}"
    #   end
    # end

    def to_array
      #has clauses has already been called, so meta is populated
      if valid?
        {
          id: id,
          component: component,
          display: @display,
          meta: evaluated_meta
          # meta comes in as:
          # foo: 'bar',
      #     other_stuff: Proc.new{'For the frontend'}
        # evaluated_meta should return
        # foo: 'bar',
        # other_stuff: 'For the frontend'
          # meta: recursively_redact_private_keys(evaluated_meta)
        }
      else
        raise ConditionError, "#{errors.full_messages}"
      end
    end

    def evaluated_meta
      recursively_evaluate_lazy_array(@meta)
    end

    #Can set meta
    # this.with_meta({
    #   foo: 'bar',
    #   other_stuff: Proc.new{'For the frontend'}
    # })

    def call_proc_if_callable(value)
      if value.respond_to? :call
        value.call
      else
        value
      end
    end

    #In HasCallbacks
    def recursively_evaluate_lazy_array(meta_hash)

      #revisit for options condition
      meta_hash.each do |key, value|
        next if key == "clauses".to_sym
        #Sanitize value if it is a Proc
        meta_hash[key] = call_proc_if_callable(value) #bar
        #See about the array casting in laravel
        if meta_hash[key].is_a? Enumerable
          recursively_evaluate_lazy_array(meta_hash[key])
        end
      end
    end
  end
end