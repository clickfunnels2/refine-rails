class Hammerstone::Refine::Inline::CriteriaController < ApplicationController
  layout false
  before_action :set_refine_filter

  def index
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter))
    @conditions = @refine_filter.instantiated_conditions
  end

  def new
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter))
    @criterion.condition_id = params[:id]
  end

  def create
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter))    
    blueprint = @refine_filter.blueprint

    Hammerstone::Refine::Filters::BlueprintEditor
      .new(@refine_filter.blueprint)
      .add(
        position: @criterion.position.to_i,
        conjunction: @criterion.conjunction,
        criterion: @criterion.to_blueprint_node
      )

    redirect_to_stable_id(@refine_filter.to_stable_id)
  end

  def edit
    @criterion = Hammerstone::Refine::Inline::Criterion
      .groups_from_filter(@refine_filter, client)
      .flatten
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

  def set_refine_filter
    @refine_filter ||= Refine::Rails.configuration.stabilizer_classes[:url]
      .new
      .from_stable_id(id: criterion_params[:stable_id])
  end

  def criterion_params
    params.require(:hammerstone_refine_inline_criterion).permit(
      :stable_id,
      :client_id,
      :condition_id,
      :position,
      :conjunction,
      input_attributes: [
        :clause,
        :date1,
        :date2,
        :days,
        :value,
        :value1,
        :value2,
        selected: [],
        count_refinement_attributes: [
          :clause,
          :value1,
          :value2
        ],
        date_refinement_attributes: [
          :clause,
          :date1,
          :date2,
          :days
        ]
      ]
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
