module Hammerstone::Refine::Conditions
  class FilterCondition < Condition
    include HasClauses
    include UsesAttributes
    include ActiveModel::Validations

    attr_reader :options

    CLAUSE_IN = Clauses::IN
    CLAUSE_NOT_IN = Clauses::NOT_IN

    def component
      "filter-condition"
    end

    def boot
      @options = nil
      with_meta({options: get_options})
      add_ensurance(ensure_options)
    end

    def set_input_parameters(input)
      @selected = input[:selected]
    end

    def select_is_array
      errors.add(:base, "Select must be an array") unless selected.is_a?(Array)
    end

    def ensure_options
      proc do
        developer_options = get_options.call
        # Options must evaluate to an array
        if !developer_options.is_a? Array
          raise "No options could be determined"
        end
        # Each option must be a hash of values that includes :id and :display
        developer_options.each do |option|
          if (!option.is_a? Hash) || option.keys.exclude?(:id) || option.keys.exclude?(:display)
            raise Hammerstone::Refine::Conditions::Errors::OptionError.new("An option must have an id and a display attribute.")
          end
        end
        ensure_no_duplicates(developer_options)
      end
    end

    def ensure_no_duplicates(developer_options)
      id_array = developer_options.map { |option| option[:id] }
      duplicates = id_array.select { |id| id_array.count(id) > 1 }.uniq
      if duplicates.present?
        raise Hammerstone::Refine::Conditions::Errors::OptionError.new("Options must have unique IDs. Duplicate #{duplicates} found.")
      end
    end

    # TODO improve this developer interface...
    def with_scope(scope)
      @options = []
      scope.all.each do |filter|
        @options << {id: filter.id, display: filter.name}
      end
      self
    end

    def stored_only
      self
    end

    def get_options
      proc do
        @options = call_proc_if_callable(options)
      end
    end

    def apply_condition(input, table, _inverse_clause)
      filter_id = input[:selected].first.to_i
      filter = Hammerstone.stabilizer_class('Stabilizers::DatabaseStabilizer').new.from_stable_id(id: filter_id)
      # TODO handle this more elegantly
      raise "Filter not found" if filter.blank?
      # TODO - Filter initial query is currently handled on the filter class. ProductFilter.where....
      # Is this the right way to handle it?
      filter.make_sub_query(filter.blueprint)
    end

    def clauses
      [
        Clause.new(CLAUSE_IN, "Includes"),
        Clause.new(CLAUSE_NOT_IN, "Does Not Include")
      ]
    end
  end
end
