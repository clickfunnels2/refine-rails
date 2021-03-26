module Hammerstone::Refine
  class Filter
    include ActiveModel::Validations
    include ActiveModel::Callbacks
    #Revisit this validation structure
    define_model_callbacks :initialize, only: [:after]
    after_initialize :valid?

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

    def table
      @table ||= initial_query.model.arel_table
    end

    def get_query
      if blueprint.present?
        @relation.where(group(make_sub_query(blueprint)))
      else
        @relation
      end
    end

    def make_sub_query(modified_blueprint, depth = 0)

      #need index control to directly skip indicies in fast forward
      index = 0
      while index < modified_blueprint.length
        criterion = modified_blueprint[index]

        #decreasing depth, pass control back to caller.
        break if criterion[:depth] < depth

        #initialize Arel::Node
        if index == 0
          subquery = apply_condition(criterion)
          index +=1
          next
        end
        # If it's a conjunction, the next condition will handle it.
        if criterion[:type] == 'conjunction'
          index +=1
          next
        end

        #Check the word on the previous blueprint method. If it is not 'and'....?
        query_method = modified_blueprint[index -1][:word] == 'and' ? 'and' : 'or'


        if criterion[:depth] > depth
          #Modify the array to send in the elements not yet handled (depth>current depth)
          new_depth_array = modified_blueprint[index..-1]

          #Return the nodes in () for elements on the same depth
          subgroup = make_sub_query(new_depth_array, depth + 1)

          #Add the subgroup to the existing query
          subquery = subquery.send(query_method, group(subgroup))

          for cursor in index..modified_blueprint.length-1 do
            if modified_blueprint[cursor][:depth] <= depth
              break
            end
          end

          #skip indexes handled by recursive call
          index = cursor
        else
          #same level
          subquery = subquery.send(query_method, apply_condition(criterion))
        end
        index += 1
      end
      subquery
    end

    def group(nodes)
      table.grouping(nodes)
    end

    def apply_condition(criterion)
      current_condition = get_condition_for_criterion(criterion)
      if current_condition
        current_condition.apply(criterion[:input], table)
      end
    end

    def get_condition_for_criterion(criterion)
      # returns the object that matches the condition (cloned in php). Adds errors if not found.
      # This checks the id on the condition such as text_test
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

