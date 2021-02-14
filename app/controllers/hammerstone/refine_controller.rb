class Hammerstone::RefineController < ApplicationController
  layout false

  def index
    @configuration = JSON.parse(params[:configuration]).deep_symbolize_keys
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(:groups, partial: 'account/shared/refine/group',
          locals: { group_id: 'group1', configuration: JSON.parse(params[:configuration], symbolize_names: true) })
      end
      format.html
    end
  end

end
