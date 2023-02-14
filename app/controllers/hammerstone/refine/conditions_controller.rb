class Hammerstone::Refine::ConditionsController < ApplicationController
  layout false
  before_action :set_builder

  def index
    @conditions = @refine_filter_builder.query.available_conditions
  end

  private

  def set_builder
    builder_params = params.require(:hammerstone_refine_filters_builder).permit(
      :blueprint_json,
      :filter_class,
      :stable_id,
      :stored_filter_id,
      :client_id,
    )

    @refine_filter_builder = Hammerstone::Refine::Filters::Builder.new(builder_params)
  end

end
