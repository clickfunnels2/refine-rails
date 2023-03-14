module Hammerstone::FilterApplicationController 
	# Optional module to get started quickly.You can send in the current controller's instance variable if you'd like to update the collection here
  # The current scope can be used to modify the query


  def apply_filter(filter_class, initial_query: nil)
    if filter_class.present?
      @stable_id = params[:stable_id]
      @refine_filter_builder = Hammerstone::Refine::Filters::Builder.new(
        stable_id: @stable_id,
        filter_class: filter_class.name,
        initial_query: initial_query)
      @refine_filter = @refine_filter_builder.refine_filter
      @refine_filter_query = @refine_filter_builder.query
    end
  end
end
