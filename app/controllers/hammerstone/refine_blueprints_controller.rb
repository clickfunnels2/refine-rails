class Hammerstone::RefineBlueprintsController < ApplicationController
  layout false

  def show
    @refine_filter = filter
  end

  def create
    @refine_filter = filter

    respond_to do |format|
      format.turbo_stream do
        if group
          render turbo_stream: turbo_stream.append(:groups, partial: 'group', locals: group)
        elsif criterion
          render turbo_stream: turbo_stream.append(
            "criteria_#{criterion[:group_id]}", partial: 'criterion', locals: criterion)
        end
      end
      format.html
    end
  end

  private

  def filter
    blueprint = JSON.parse(filter_params[:blueprint]).map(&:deep_symbolize_keys)
    filterClass = filter_params[:filter].constantize
    filterClass.new(blueprint)
  end

  def filter_name
    filter_params[:filter]
  end

  def blueprint
    filter_params[:blueprint]
  end

  def filter_params
    params.permit(:filter, :blueprint)
  end

  def group
    params.has_key?(:group) && JSON.parse(params.require(:group)).deep_symbolize_keys
  end

  def criterion
    params.has_key?(:criterion) && JSON.parse(params.require(:criterion)).deep_symbolize_keys
  end
end
