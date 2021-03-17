class Hammerstone::RefineBlueprintsController < ApplicationController
  layout false

  def show
    @refine_filter = filter
  end

  private

  def filter
    blueprint = JSON.parse(filter_params[:blueprint]).map(&:deep_symbolize_keys)
    filterClass = filter_params[:filter].constantize
    filterClass.new(blueprint)
  end

  def filter_params
    params.permit(:filter, :blueprint)
  end
end
