class Hammerstone::Refine::ConditionsController < ApplicationController
  layout false
  before_action :set_builder

  def index
    refine_filter = @refine_filter_builder.refine_filter
    @conditions = @refine_filter_builder.query.available_conditions
    @conditions.each do |c|
      c.set_filter refine_filter
      refine_filter.translate_display(c)
    end
  end

  def new
    @criterion = Hammerstone::Refine::Filters::Criterion.new(
      condition_id: params[:id],
      query: @refine_filter_builder.query,
      input: {
        clause: params[:clause].presence
      }
    )
  end

  def edit
    @criterion = @refine_filter_builder
      .query
      .criteria
      .detect { |c| c.uid.to_s == params[:id] }
  end

  def create
    refine_filter = @refine_filter_builder.refine_filter
    blueprint = refine_filter.blueprint

    Hammerstone::Refine::Filters::BlueprintEditor
      .new(refine_filter.blueprint)
      .add(criterion: {
        condition_id: params[:condition_id],
        input: {
          clause: params[:clause],
          value: params[params[:condition_id]]
        }    
      })

    redirect_to_stable_id(refine_filter.to_stable_id)
  end

  def update
    refine_filter = @refine_filter_builder.refine_filter
    Hammerstone::Refine::Filters::BlueprintEditor
      .new(refine_filter.blueprint)
      .update(params[:id].to_i, criterion: {
        input: {
          clause: params[:clause],
          value: params[params[:condition_id]]
        }    
      })

    redirect_to_stable_id(refine_filter.to_stable_id)
  end

  def destroy
    refine_filter = @refine_filter_builder.refine_filter
     Hammerstone::Refine::Filters::BlueprintEditor
      .new(refine_filter.blueprint)
      .delete(params[:id].to_i)

    redirect_to_stable_id(refine_filter.to_stable_id)
  end

  private

  def redirect_to_stable_id stable_id
    # update_stable_id in url
    uri = URI(request.referrer)
    new_query_ar = URI.decode_www_form(String(uri.query))
    new_query_ar.reject! { |(k, _v)| k == "stable_id" }
    new_query_ar << ["stable_id", stable_id]
    uri.query = URI.encode_www_form(new_query_ar)
    
    redirect_to uri.to_s
  end

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
