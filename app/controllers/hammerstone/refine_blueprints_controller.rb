class Hammerstone::RefineBlueprintsController < ApplicationController
  layout false

  def index
    @configuration = JSON.parse(params[:configuration]).deep_symbolize_keys
  end

  def create
    conditions = JSON.parse(params[:conditions]).map(&:deep_symbolize_keys)
    group_id = params[:group_id]
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(:groups, partial: 'group', locals: {
          group_id: group_id, conditions: conditions, criteria: []})
      end
      format.html
    end
  end

  def update
    byebug
  end
end
