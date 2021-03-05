module Hammerstone::Refine
  class Filter
    include ActiveModel::Validations
    include ActiveModel::Callbacks
    #Validation each condition, check condition class
    define_model_callbacks :initialize, only: [:after]
    after_initialize :valid?
    # Configuration and Blueprint are different
    # Config sends array of conditions to front end

    attr_reader :blueprint

    def initialize(blueprint)
      run_callbacks :initialize do
        #If using this in test mode, `blueprint` will be an instance of
        #`Blueprint` and the value must be extracted
        if blueprint.is_a? Blueprints::Blueprint
          blueprint = blueprint.to_array
        end
        @blueprint = blueprint
        @relation = initial_query
      end
    end

    def initial_query
      raise NotImplementedError
    end

    def get_query
      make_sub_query
    end

    def make_sub_query
      blueprint.each_with_index do |criterion, index|
        # If it's a conjunction, the next condition will handle it.
        next if criterion[:type] == 'conjunction'

        # We start every group with `where`.
        if index == 0
          query_method = 'where'
        else
          #Check the word on the previous blueprint method. If it is not 'and'....?
          query_method = blueprint[index -1][:word] == 'and' ? 'where' : 'or'
        end
        # Sort out wheres, this is calling `where` in the text condition, need to prepend w/ method
        apply_condition!(criterion)
      end
      @relation
    end

    def apply_condition!(criterion)
      current_condition = get_condition_for_criterion(criterion)
      if current_condition
        @relation = current_condition.apply_condition(@relation, criterion[:input])
      end
    end

    def get_condition_for_criterion(criterion)
      # returns the object that matches the condition (cloned in php). Adds errors if not found.
      returned_object = conditions.find { |condition| condition.id == criterion[:condition_id] }

      if returned_object.nil?
        errors.add(:filter, "The condition ID #{criterion[:condition_id]} was not found")
      end

      returned_object
    end

    def configuration
      {
        type: 'Hammerstone',
        class_name: self.class.name,
        blueprint: @blueprint,
        conditions: conditions_to_array,
        stable_id: 'dontcare'
      }
    end

    def conditions_to_array
      conditions.map{| condition| condition.to_array }
    end
  end
end

