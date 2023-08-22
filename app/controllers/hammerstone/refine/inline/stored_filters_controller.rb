class Hammerstone::Refine::Inline::StoredFiltersController < ApplicationController
  layout false
  before_action :set_refine_filter


  def index
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params)
    @stored_filters = Hammerstone::Refine::StoredFilter.where(filter_type: @refine_filter.type)
    @stored_filters = instance_exec(@stored_filters, &Refine::Rails.configuration.stored_filter_scope)
  end

  def find
    @stored_filter = Hammerstone::Refine::StoredFilter.find_by(id: params[:id], filter_type: @refine_filter.type)
    handle_filter_update @stored_filter.refine_filter.to_stable_id
  end

  def new
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params)
    @stored_filter = Hammerstone::Refine::StoredFilter.new(filter_type: @refine_filter.type)
  end

  def create
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params)
    @stored_filter = Hammerstone::Refine::StoredFilter.new(stored_filter_params.merge(
        state: @refine_filter.state,
        filter_type: @refine_filter.type,
        **instance_exec(&Refine::Rails.configuration.custom_stored_filter_attributes)
      )
    )

    if @stored_filter.save
      handle_filter_update @stored_filter.refine_filter.to_stable_id
    else
      render :new, status: :unprocessable_entity
    end
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
      :position,
      :conjunction
    )
  end

  def stored_filter_params
    params.require(:hammerstone_refine_stored_filter).permit(:name)
  end

  # either directly redirect or emit a `filter-submit-success` event
  def handle_filter_update stable_id
    # update_stable_id in url
    uri = URI(request.referrer)
    new_query_ar = URI.decode_www_form(String(uri.query))
    new_query_ar.reject! { |(k, _v)| k == "stable_id" }
    new_query_ar << ["stable_id", stable_id]
    uri.query = URI.encode_www_form(new_query_ar)

    respond_to do |format|
      format.turbo_stream do
        @refine_stable_id = stable_id
        @url_for_redirect = uri
        @refine_client_id = criterion_params[:client_id]
        @refine_filter = @stored_filter.refine_filter
        render :find
      end
      format.html {redirect_to uri.to_s }
    end
  end
end
