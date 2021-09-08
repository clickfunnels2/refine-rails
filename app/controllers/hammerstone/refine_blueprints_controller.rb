class Hammerstone::RefineBlueprintsController < ApplicationController
  layout false

  def show
    @refine_filter = filter
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
    params.permit(:filter, :stable_id, :blueprint)
  end

  def blueprint
    return [] unless filter_params[:blueprint]

    JSON.parse(filter_params[:blueprint]).map(&:deep_symbolize_keys)
  end

  def stable_id
    filter_params[:stable_id]
  end
end
