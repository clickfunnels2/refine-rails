class Hammerstone::RefineBlueprintsController < ApplicationController
  layout false

  def show
    @configuration = JSON.parse(params[:configuration]).deep_symbolize_keys
  end

  def create
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

  def group
    params.has_key?(:group) && JSON.parse(params.require(:group)).deep_symbolize_keys
  end

  def criterion
    params.has_key?(:criterion) && JSON.parse(params.require(:criterion)).deep_symbolize_keys
  end
end
