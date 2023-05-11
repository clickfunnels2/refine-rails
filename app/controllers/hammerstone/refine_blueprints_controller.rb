class Hammerstone::RefineBlueprintsController < ApplicationController
  layout false
  before_action :set_builder
  before_action :set_filter
  before_action :set_form

  # entry point for initial render of the filter builder
  def new
    @show_stored_filters = params[:stored_filters]
  end

  # refresh the filter builder
  def show
    if @refine_filter_query.valid?
      @stable_id = @refine_filter.to_stable_id
    end

    # don't display errors
    @refine_filter_query.clear_errors unless params[:include_errors]

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  # handles filter submission
  def create
    if @refine_filter_query.valid?
      # set stable_id
      @stable_id = @refine_filter.to_stable_id

      # set url
      uri = URI(request.referrer)
      new_query_ar = URI.decode_www_form(String(uri.query))
      new_query_ar.reject! { |(k, _v)| k == "stable_id" }
      new_query_ar << ["stable_id", @stable_id]
      uri.query = URI.encode_www_form(new_query_ar)
      @url_for_redirect = uri.to_s
      @filter_submit_success = true
    end
  end

  def stored_filters
    render partial: "stored_filters", layout: false
  end

  def validate
    if @refine_filter_query.valid?
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def set_builder
    builder_params = params.require(:hammerstone_refine_filters_builder).permit(
      :blueprint_json,
      :filter_class,
      :stable_id,
      :stored_filter_id,
      :client_id
    )

    @refine_filter_builder = Hammerstone::Refine::Filters::Builder.new(builder_params)
  end

  def set_filter
    @refine_filter = @refine_filter_builder.refine_filter
  end

  def set_form
    @refine_filter_query = @refine_filter_builder.query
  end
end
