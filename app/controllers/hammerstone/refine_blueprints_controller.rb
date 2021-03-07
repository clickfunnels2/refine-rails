class Hammerstone::RefineBlueprintsController < ApplicationController
  layout false

  def show
    @refine_filter = filter
  end

  def create
    filterClass = filter_params[:filterName].constantize
    @refine_filter = filterClass.new []

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
    filterClass = filter_params[:filterName].constantize
    filterClass.new(blueprint)
  end

  def filter_name
    filter_params[:filterName]
  end

  def filter_params
    params.permit(:filterName, :blueprint)
  end

  def group
    params.has_key?(:group) && JSON.parse(params.require(:group)).deep_symbolize_keys
  end

  def criterion
    params.has_key?(:criterion) && JSON.parse(params.require(:criterion)).deep_symbolize_keys
  end
end
