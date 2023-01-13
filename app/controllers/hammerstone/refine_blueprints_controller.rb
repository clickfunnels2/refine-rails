class Hammerstone::RefineBlueprintsController < ApplicationController
  layout false
  before_action :set_filter

  # entry point for initial render of the filter builder
  def new
    @refine_filter = filter
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter)
    @show_stored_filters = params[:stored_filters]
  end

  # refresh the filter builder
  def show
    if @form.valid?
      @stable_id = @refine_filter.to_stable_id
    end

    # don't display errors
    @form.clear_errors

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  # handles filter submission
  def create
    if @form.valid?
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
    @refine_filter = filter
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter, id: params[:form_id])
    render partial: "stored_filters", layout: false
  end

  private

  def set_filter
    if stable_id = filter_params[:stable_id]
      @refine_filter = Hammerstone.stabilizer_class('Stabilizers::UrlEncodedStabilizer').new.from_stable_id(id: stable_id)
    elsif filter_params[:blueprint]
      klass = filter_params[:filter].constantize
      blueprint = JSON.parse(filter_params[:blueprint]).map(&:deep_symbolize_keys)
      @refine_filter = klass.new blueprint
    else
      klass = filter_params[:filter].constantize
      @refine_filter = klass.new([])
    end


  end

  def set_form
     @form_id = filter_params[:form_id]
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter, id: @form_id)
  end

  def filter_params
    params.permit(:filter, :stable_id, :blueprint, :form_id)
  end
end
