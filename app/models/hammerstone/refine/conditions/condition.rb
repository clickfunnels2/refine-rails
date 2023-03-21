module Hammerstone::Refine::Conditions
  class Condition
    include ActiveModel::Validations

    validates :clause, presence: true
    validate :clause_in_approved_list?

    # TODO remove hasclauses here, rename boot_has_clauses
    include HasClauses
    include HasMeta
    include UsesAttributes
    include HasRefinements

    attr_reader :ensurances, :before_validations, :clause, :filter
    attr_accessor :display, :id, :is_refinement, :attribute

    def initialize(id = nil, display = nil)
      # Capture display value if sent it. Not translated, takes precedence
      # If no display value explicitly sent, use locales to translate in translate_display
      @display = display
      @id = id
      # Optimistically set attribute to the id
      @attribute = id
      @rules = {}

      # Ensurance validations -> every condition must have an id and an attribute evaluated after
      # developer configuration
      @ensurances = []
      add_ensurance(ensure_id)
      add_ensurance(ensure_attribute_configured)

      @before_validations = []

      # Interpolate later in life for each class that needs it - not everyone needs it
      boot_has_clauses

      # Allow each condition to set state post initialization
      boot
      @on_deepest_relationship = false
      @is_refinement = false
      # Refinements variables
      @date_refinement_proc = nil
      @count_refinement_proc = nil
      @filter_refinement_proc = nil
    end

    def before_validate(callable)
      @before_validations << callable
    end

    def add_ensurance(callable)
      @ensurances << callable
    end

    def with_display(value)
      @display = value
      self
    end

    def ensure_attribute_configured
      proc do
        if @attribute.nil?
          errors.add(:base, "An attribute is required.")
        end
      end
    end

    def ensure_id
      proc do
        if @id.nil?
          errors.add(:base, "Every condition must have an ID")
        end
      end
    end

    # Boot the traits first, so any extended conditions
    # can override the traits if they need to.
    def boot_traits
    end

    def boot
    end

    def add_rules(new_rules, new_messages = {})
      # TODO add messages if desired
      @rules.merge!(new_rules)
      add_messages(new_messages)
      self
    end

    def messages
      @messages ||= {}
    end

    def add_messages(new_messages)
      messages.merge!(new_messages)
      self
    end

    def run_ensurance_validations
      ensurances.each do |function|
        call_proc_if_callable(function)
      end
    end

    def run_before_validate_validations(input)
      before_validations.each do |function|
        if function.respond_to? :call
          function.call(input)
        else
          function
        end
      end
    end

    # Applies the criterion which can be a relationship condition
    #
    # @param [Hash] input The user's input
    # @param [Arel::Table] table The arel_table the query is built on 
    # @param [ActiveRecord::Relation] initial_query The base query the query is built on 
    # @return [Arel::Node] 
    def apply(input, table, initial_query, inverse_clause=false)
      table ||= filter.table
      # Ensurance validations are checking the developer configured correctly
      run_ensurance_validations
      # Allow developer to modify user input
      # TODO run_before_validate(input) -> what is this for?

      run_before_validate_validations(input)

      # TODO Determine right place to set the clause
      validate_user_input(input)
      if input.dig(:filter_refinement).present?

        filter_condition = call_proc_if_callable(@filter_refinement_proc)
        # Set the filter on the filter_condition to be the current_condition's filter
        filter_condition.set_filter(filter)
        filter_condition.is_refinement = true

        # Applying the filter condition will modify pending relationship subqueries in place
        filter_condition.apply(input.dig(:filter_refinement), table, initial_query)
        input.delete(:filter_refinement)
      end

      if is_relationship_attribute?
        apply_relationship_attribute(input: input, query: initial_query)
        return
      end
      # No longer a relationship attribute, apply condition normally
      nodes = apply_condition(input, table, inverse_clause)
      if !is_refinement && has_any_refinements?
        refined_node = apply_refinements(input)
        # Count refinement will return nil because it directly modified pending relationship subquery
        nodes = nodes.and(refined_node) if refined_node
      end
      nodes
    end

    def set_input_parameters(input)
      # Placeholder for conditions that do not need this method
    end

    def clause_in_approved_list?
      # Is the requested clause in the approved list configured by developer?
      unless get_clauses.call.map(&:id).include? clause
        errors.add(:base, "The clause with id #{clause} was not found")
      end
    end

    def validate_user_input(input)
      evaluated_rules = recursively_evaluate_lazy_enumerable(@rules)
      # Set input parameters on the condition in order to use condition level validations
      # TODO set this somewhere more obvious 
      @clause = input[:clause]
      set_input_parameters(input)
      evaluated_rules.each_pair do |k, v|
        if input[k].blank?
          errors.add(:base, "A #{k} is required")
        end
      end
      # Errors added to the errors array by individual conditions and standard rails validations
      if errors.any? || !valid?
        # When the error is rescued, it will stringify the message.
        raise Errors::ConditionClauseError.new(
          errors.attribute_names.map{|name| errors[name].join}.to_sentence,
          errors: errors
        )
      end
    end

    def clause_exists?(input)
      current_clause = clauses.select { |clause| clause.id == input[:clause] }
      current_clause.present?
    end

    def component
      raise NotImplementedError
    end

    def human_readable(input)
      raise NotImplementedError
    end

    def apply_condition(input, table, _inverse_clause)
      raise NotImplementedError
    end

    def set_filter(filter)
      @filter = filter
      self
    end

    def to_array(allow_errors: false)
      # Has clauses has already been called, so meta is populated with possible closures to evaluate
      # Run ensurance validations will populate the errors array on the object
      run_ensurance_validations

      if errors.any? && !allow_errors
        raise ConditionError, errors.full_messages.join(". ")
      end

      {
        id: id,
        component: component,
        display: @display,
        meta: evaluated_meta,
        refinements: refinements_to_array
      }
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

    # In HasCallbacks
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

    private

    def arel_attribute(table)
      return @attribute if @attribute.is_a? Arel::Nodes::SqlLiteral

      table[:"#{attribute}"]
    end
  end
end
