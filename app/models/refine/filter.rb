module Refine
  class Filter
    include ActiveModel::Validations
    include ActiveModel::Callbacks
    include TracksPendingRelationshipSubqueries
    include Stabilize
    include Internationalized
    include Inspector
    # This validation structure sents `initial_query` as the method to validate against
    define_model_callbacks :initialize, only: [:after]
    after_initialize :valid?

    def self.model_name
      name.sub(/(::)?Filter$/, "").singularize
    end

    def self.model
      @model ||= model_name.constantize
    end

    cattr_accessor :default_stabilizer, default: nil, instance_accessor: false
    cattr_accessor :criteria_limit, default: 5, instance_accessor: true

    attr_reader :blueprint, :initial_query

    # Give each Filter subclass its own default_condition_id,
    # that is also also readable from instances
    #
    # class UserFilter
    #   self.default_condition_id = "email"
    # # ...
    # end
    #
    class << self
      attr_accessor :default_condition_id
    end
    delegate :default_condition_id, to: :class

    def initialize(blueprint = nil, query_scope = nil)
      run_callbacks :initialize do
        # If using this in test mode, `blueprint` will be an instance of
        # `Blueprint` and the value must be extracted
        if blueprint.is_a? Blueprints::Blueprint
          blueprint = blueprint.to_array
        end
        @initial_query = query_scope
        @blueprint = blueprint
        @relation = initial_query
        @immediately_commit_pending_relationship_subqueries = false
        @@default_stabilizer = Refine::Stabilizers::UrlEncodedStabilizer
      end
    end

    def human_readable_criterions
      output = []
      if blueprint.present?
        blueprint.each do |criterion|
          if criterion[:type] == "conjunction"
            output << criterion[:word]
          else
            condition = get_condition_for_criterion(criterion)
            text = condition.human_readable(criterion[:input])
            if condition.has_date_refinement?
              date_refinement_condition = condition.has_date_refinement?.call
              text += date_refinement_condition.human_readable(criterion[:input][:date_refinement])
            end
            output << text
          end
        end
      end
      output
    end

    def automatically_stabilize?
      true
    end

    # e.g. ContactsFilter -> Contact
    def model
      initial_query&.model || self.class.model
    end

    def table
      model.arel_table
    end

    def valid_query?
      get_query
      errors.none?
    end

    def get_query
      raise "Initial query must exist" if initial_query.nil?
      if self.class.included_modules.include?(Refine::FlatQueryTools) && can_use_flat_query?
        get_flat_query
      else
        get_complex_query
      end
    end

    def get_query!
      result = get_query
      raise Refine::InvalidFilterError.new(filter: self) unless errors.none?
      result
    end

    def get_complex_query
      if blueprint.present?
        @relation.where(group(make_sub_query(blueprint)))
      else
        @relation
      end
    end

    def add_nodes_to_query(subquery:, nodes:, query_method:)
      # Apply existing nodes to existing subquery
      if subquery.present? && nodes.present?
        subquery = if query_method == "and"
          # Apply the nodes using the AREL AND method
          subquery.send(query_method, group(nodes))
        else
          # Override the AREL OR method in order to remove the automatic parens
          Arel::Nodes::Or.new(subquery, group(nodes))
        end
      # No nodes returned, do nothing
      elsif subquery.present? && nodes.blank?
        subquery
      # Subquery has not yet been initialized, initialize with new nodes - must use !nil? here, present/exists/blank etc don't
      # account for AR::Relation object.
      elsif subquery.blank? && !nodes.nil?
        subquery = group(nodes)
      end
      subquery
    end

    def make_sub_query(modified_blueprint, depth = 0, subquery = nil)
      # Need index control to directly skip indicies in fast forward (recursive call)
      index = 0
      while index < modified_blueprint.length
        criterion = modified_blueprint[index]
        # Decreasing depth, pass control back to caller
        break if criterion[:depth] < depth

        # If it's a conjunction, the next condition will handle it.
        if criterion[:type] == "conjunction"
          index += 1
          next
        end

        # Check the word on the previous blueprint method. If it is not 'and'....?
        query_method = if index == 0
          "and"
        else
          modified_blueprint[index - 1][:word] == "and" ? "and" : "or"
        end

        # If the new depth is deeper than our current depth, that means we're
        # starting a new group. We'll recursively call this method again
        # with a subset of the blueprint.
        if criterion[:depth] > depth
          # Modify the array to send in the elements not yet handled (depth>current depth)
          new_depth_array = modified_blueprint[index..-1]

          # Return the nodes in () for elements on the same depth
          recursive_nodes = make_sub_query(new_depth_array, depth + 1)

          # Add the recursive subquery nodes to the existing query and modify the query
          subquery = add_nodes_to_query(subquery: subquery, nodes: recursive_nodes, query_method: query_method)

          # Skip indexes handled by recursive call
          index = fast_forward(index, modified_blueprint, depth) + 1
          next
        end
        # If there are any ORs at this depth, commit subqueries
        @immediately_commit_pending_relationship_subqueries = if modified_blueprint.select { |item| (item[:type] == "conjunction" && item[:word] == "or" && item[:depth] == depth) }.present?
          true
        else
          false
        end

        # If it is a relationship attribute apply_condition will call apply_relationship_attribute which will set up the pending relationship
        # subquery but will not return a value.
        # apply condition is NOT idempotent, hence the placeholder var
        nodes_to_apply = apply_condition(criterion)
        # If an error has been added to the errors array from apply_condition, do not continue execution at this level
        if errors.any?
          index += 1
          next
        end

        subquery = add_nodes_to_query(subquery: subquery, nodes: nodes_to_apply, query_method: query_method)

        if @immediately_commit_pending_relationship_subqueries.present?
          committed_nodes_from_pending = commit_pending_relationship_subqueries
          subquery = add_nodes_to_query(subquery: subquery, nodes: committed_nodes_from_pending, query_method: query_method)
        end

        index += 1
      end

      unless errors.any?
        final_depth_nodes = commit_pending_relationship_subqueries
        # Add nodes to existing query and return existing query
        add_nodes_to_query(subquery: subquery, nodes: final_depth_nodes, query_method: query_method)
      end
    end

    def fast_forward(index, modified_blueprint, depth)
      fast_forward_index = (index..modified_blueprint.length - 1).each do |cursor|
        break cursor if modified_blueprint[cursor][:depth] <= depth
      end
      # TODO refactor for clarity. If I break early from the iterator I have an int. If not,
      # default to modfied_blueprint.length -1 as the correct value
      (fast_forward_index.is_a? Integer) ? fast_forward_index : modified_blueprint.length - 1
    end

    def group(nodes)
      Arel::Nodes::Grouping.new(nodes)
    end

    def apply_condition(criterion)
      begin
        condition = get_condition_for_criterion(criterion)
        get_condition_for_criterion(criterion)&.apply(criterion[:input], table, initial_query, false, nil)
      rescue Refine::Conditions::Errors::ConditionClauseError => e
        e.errors.each do |error|
          errors.add(:base, error.full_message, criterion_uid: criterion[:uid])
        end
      end
    end

    def get_condition_for_criterion(criterion)
      # Returns the object that matches the condition. Adds errors if not found.
      # This checks the id on the condition such as text_test
      returned_object = conditions.find { |condition| condition.id == criterion[:condition_id] }
      if returned_object.nil?
        errors.add(:filter, "The condition ID #{criterion[:condition_id]} was not found")
      else
        # Set filter variable on condition
        instantiate_condition(returned_object)
      end
      # Must duplicate the condition so nested attributes don't bleed into one another
      returned_object.dup
    end

    def configuration
      {
        type: "Refine",
        class_name: self.class.name,
        blueprint: @blueprint,
        conditions: conditions_to_array,
        stable_id: to_optional_stable_id
      }
    end

    def conditions_to_array
      return nil unless conditions
      # Set filter object on condition and return to_array
      conditions.map { |condition| instantiate_condition(condition) }.map(&:to_array)
    end

    def instantiate_condition(condition)
      condition.set_filter(self)
      translate_display(condition)
      condition
    end

    # Set filter object on condition and sort alphabetically
    def instantiated_conditions
      conditions
        .map { |c| instantiate_condition(c.dup) }
        .sort_by { |c| c.display.to_s.downcase }
    end

    def translate_display(condition)
      # If there are no locale definitions for this condition's subject, we can allow I18n to use a human-readable version of the ID.
      # But, ideally, they have locales defined and we can find one of those.
      label_fallback = {default: condition.id.humanize(keep_id_suffix: true).titleize}
      condition.display = condition.display || I18n.t(".filter.conditions.#{condition.id}.label", default: I18n.t(".fields.#{condition.id}.label", **label_fallback))
    end

    def state
      {
        type: type,
        blueprint: blueprint
      }.to_json
    end

    def type
      self.class.name
    end

    def self.from_state(state, initial_query = nil)
      klass = state[:type].constantize
      filter = klass.new(state[:blueprint], initial_query)
    end

    def self.default_stable_id_generator(klass)
      if klass.method_defined?(:to_stable_id) && klass.method_defined?(:from_stable_id)
        @@default_stabilizer = klass
      else
        raise ArgumentError.new('Given class doesn\'t implement to_stable_id and from_stable_id!')
      end
    end

    def to_stable_id
       Refine::Rails.configuration.stabilizer_classes[:url].new.to_stable_id(filter: self)
    end

    def blueprint_criteria
      blueprint&.filter { |node| node.is_a?(Hash) && node[:type] == 'criterion' }.to_a
    end

    def criteria_limit_exceeded?
      criteria_limit_set? && blueprint_criteria.length > criteria_limit
    end

    def criteria_limit_reached?
      criteria_limit_set? && blueprint_criteria.length >= criteria_limit
    end

    def criteria_limit_set?
      criteria_limit.to_i.positive?
    end

    def has_category_ordering?
      respond_to?(:category_order) && category_order.is_a?(Array) && category_order.any?
    end

    def clear_blueprint!
      @blueprint = []
    end

  end
end
