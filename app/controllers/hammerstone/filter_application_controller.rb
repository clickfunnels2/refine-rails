module Hammerstone::FilterApplicationController 
	# Optional module to get started quickly.You can send in the current controller's instance variable if you'd like to update the collection here
  # The current scope can be used to modify the query


  def apply_filter(filter_class, initial_query: nil, builder_class: Hammerstone::Refine::Filters::Builder)
    if filter_class.present?
      @stable_id = params[:stable_id]
      @refine_filter_builder = builder_class.new(
        stable_id: @stable_id,
        filter_class: filter_class.name,
        initial_query: initial_query)
      @refine_filter = @refine_filter_builder.refine_filter
    end
  end

  # Use this on pages that use the new inline filter
  def apply_inline_filter(filter_class, initial_query: nil)
    stable_id = params[:stable_id]

    if stable_id.present?
      @refine_filter = Refine::Rails.configuration.stabilizer_classes[:url].new.from_stable_id(id: stable_id, initial_query: initial_query)
    else
      json = blueprint_json || "[]"
      blueprint = JSON.parse(json).map(&:deep_symbolize_keys)
      @refine_filter = filter_class.constantize.new(blueprint, initial_query)
    end

    @refine_inline_criterion = Hammerstone::Refine::Inline::Criterion.new(stable_id: stable_id)
    @refine_filter_criterion.client_id = SecureRandom.uuid
  end
end
