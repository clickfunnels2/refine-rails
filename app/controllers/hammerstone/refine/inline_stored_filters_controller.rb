class Hammerstone::Refine::InlineStoredFiltersController < ApplicationController
  layout false
  before_action :set_builder

  def index
    @stored_filters = Hammerstone::Refine::StoredFilter.where(filter_type: @refine_filter_builder.filter_class)
    @stored_filters = instance_exec(@stored_filters, &Refine::Rails.configuration.stored_filter_scope)
  end

  def find
    @stored_filter = Hammerstone::Refine::StoredFilter.find_by(id: params[:id])
    redirect_to_stable_id @stored_filter.refine_filter.to_stable_id
  end

  def new
    @stored_filter = Hammerstone::Refine::StoredFilter.new(filter_type: @refine_filter_builder.filter_class)
  end

  def create
    @refine_filter = @refine_filter_builder.refine_filter

    @stored_filter = Hammerstone::Refine::StoredFilter.new(name: params[:name], state: @refine_filter.state, filter_type: @refine_filter.type, **instance_exec(&Refine::Rails.configuration.custom_stored_filter_attributes))
    @refine_filter_query = @refine_filter_builder.query

    if !@refine_filter_query.valid?
      # replace the filter form with errors
      render :create
    elsif !@stored_filter.save
      # replace the stored filter form
      render :new, status: :unprocessable_entity
    else
      # return to stored filters header and load the filter into the query builder
      @refine_filter_builder.stored_filter_id = @stored_filter.id
      render :find
    end
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
      :conjunction,
      :position
    )

    @refine_filter_builder = Hammerstone::Refine::Filters::BuilderInline.new(builder_params)
  end
end
