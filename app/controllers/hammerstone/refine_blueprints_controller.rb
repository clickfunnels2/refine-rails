class Hammerstone::RefineBlueprintsController < Account::ApplicationController
  layout false

  def show
    @refine_filter = filter
    @method = filter_params[:method]
    # TODO: Fix validation
    # @refine_filter.validate_only
  end

  def update_stable_id
    filterClass = filter_params[:filter].constantize
    # TODO can't re-use blueprint method here b/c the params are coming in as a nested params hash, 
    # in the show method they are a string. 
    blueprint_details = params.to_unsafe_h[:blueprint]
    filter = filterClass.new blueprint_details
    filter_id = Stabilizers::UrlEncodedStabilizer.new.to_stable_id(filter: filter)
    render json: { filter_id: filter_id }, status: :ok
  end

  private

  def filter
    if stable_id
      Stabilizers::UrlEncodedStabilizer.new.from_stable_id(id: stable_id)
    else
      filterClass = filter_params[:filter].constantize
      filterClass.new blueprint
    end
  end

  def filter_params
    params.permit(:filter, :stable_id, :blueprint, :method)
  end

  def blueprint
    return [] unless filter_params[:blueprint]
    JSON.parse(filter_params[:blueprint]).map(&:deep_symbolize_keys)
  end

  def stable_id
    filter_params[:stable_id]
  end
end
