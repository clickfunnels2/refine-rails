class Hammerstone::RefineController < ApplicationController
  layout false

  def index
    @configuration = JSON.parse(params[:configuration]).deep_symbolize_keys
  end

  def create
    configuration = JSON.parse(params[:configuration]).deep_symbolize_keys
    conditions = configuration[:conditions]
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(:groups, partial: 'group', locals: {
          group_id: 'group1', conditions: conditions, criteria: []})
      end
      format.html
    end
  end

end
