class Hammerstone::RefineBlueprintsController < ApplicationController
  layout false

  def show
    @configuration = JSON.parse(params[:configuration]).deep_symbolize_keys
  end

  def create
    conditions = JSON.parse(params[:conditions]).map(&:deep_symbolize_keys)
    group = JSON.parse(params[:group])

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(:groups, partial: 'group', locals: group.merge(conditions: conditions).deep_symbolize_keys)
      end
      format.html
    end
  end

  def update
    byebug
  end
end
