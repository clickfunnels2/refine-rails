module Hammerstone::FilterApplicationController 
	# Optional module to get started quickly.You can send in the current controller's instance variable if you'd like to update the collection here
  # The current scope can be used to modify the query
  # If you would like to *send in* the initial query at runtime, use the HammerstoneFilterWithInitialQuery module 


  def apply_filter(child_filter_class, current_scope = nil, instance_variable_name = nil)
    if child_filter_class.present?
      @stored_filter = nil
      # @stored_filter = Hammerstone::Refine::StoredFilter.find_by(id: stored_filter_id)
      @stable_id = stable_id
      @refine_filter = if stable_id
        Hammerstone::Refine::Stabilizers::UrlEncodedStabilizer.new.from_stable_id(id: stable_id)
      elsif @stored_filter
        @stored_filter.refine_filter
      else
        child_filter_class.new([])
      end
      # Optionally set the instance variable to be the results of the query. 
      # instance_variable_set('example: @contacts', @refine_filter.get_query)

      # This takes a current scope from tab, etc and merges it in.
      # instance_variable_set(children_instance_variable_name, children_instance_variable.merge(current_scope)) if current_scope
    end
  end


  def filter_params
    # The filter can come in as a stored_filter_id (database stabilized) or a stable_id (url encoded)
    params.permit(:filter, :stable_id, :blueprint, :conditions, :clauses, :name, :stored_filter_id)
  end

  def stored_filter_id
    filter_params[:stored_filter_id]
  end

  def stable_id
    filter_params[:stable_id]
  end
end