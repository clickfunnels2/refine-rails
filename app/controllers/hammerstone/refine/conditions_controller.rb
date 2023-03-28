class Hammerstone::Refine::ConditionsController < ApplicationController
  layout false
  before_action :set_refine_filter

  def index
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params)
    @conditions = @refine_filter.available_conditions
    @conditions.each do |c|
      c.set_filter refine_filter
      refine_filter.translate_display(c)
    end
  end

  def new
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params)
  end

  def create
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params)    
    blueprint = refine_filter.blueprint

    Hammerstone::Refine::Filters::BlueprintEditor
      .new(refine_filter.blueprint)
      .add(**@criterion.to_editor_args)

    redirect_to_stable_id(refine_filter.to_stable_id)
  end

  def edit
    @criterion = Hammerstone::Refine::Inline::Criterion
      .criteria_from_blueprint(@refine_filter.blueprint)
      .detect { |c| c.position.to_s == params[:id] }

    @criterion.attributes = criterion_params
  end

  def update
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params) 
    Hammerstone::Refine::Filters::BlueprintEditor
      .new(@refine_filter.blueprint)
      .update(@criterion)

    redirect_to_stable_id(refine_filter.to_stable_id)
  end

  def destroy
    Hammerstone::Refine::Filters::BlueprintEditor
      .new(@refine_filter.blueprint)
      .delete(params[:id].to_i)

    redirect_to_stable_id(refine_filter.to_stable_id)
  end

  private

  def refine_filter
    @refine_filter ||= Refine::Rails.configuration.stabilizer_classes[:url]
      .new
      .from_stable_id(criterion_params[:stable_id])
  end

  def criterion_params
    params.require(:hammerstone_refine_inline_criterion).permit(
      :stable_id,
      :client_id,
      :condition_id,
      :input,
      :position,
      :conjunction,
      input_attributes: {
        :clause,
        :date1,
        :date2,
        :days,
        :value,
        :value1,
        :value2,
        selected: [],
        :count_refinement_attributes: {
          :clause,
          :value1,
          :value2
        },
        :date_refinement_attributes: {
          :clause,
          :date1,
          :date2,
          :days
        }
      }
    )
  end

  def redirect_to_stable_id stable_id
    # update_stable_id in url
    uri = URI(request.referrer)
    new_query_ar = URI.decode_www_form(String(uri.query))
    new_query_ar.reject! { |(k, _v)| k == "stable_id" }
    new_query_ar << ["stable_id", stable_id]
    uri.query = URI.encode_www_form(new_query_ar)
    
    redirect_to uri.to_s
  end

  def input_params
    params.permit(*Hammerstone::Refine::Filters::BlueprintEditor::INPUT_ATTRS)
  end
end
