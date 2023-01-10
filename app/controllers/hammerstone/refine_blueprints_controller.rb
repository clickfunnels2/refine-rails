class Hammerstone::RefineBlueprintsController < ApplicationController
  layout false

  # entry point for initial render of the filter builder
  def new
    @refine_filter = filter
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter)
    @show_stored_filters = params[:stored_filters]
  end

  # refresh the filter builder
  def show
    @refine_filter = filter
    @form_id = filter_params[:form_id]
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter, id: @form_id)
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  # handles filter submission
  def create
    @refine_filter = filter
    @form_id = filter_params[:form_id]
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter, id: @form_id)

    if @form.valid?
      uri = URI(request.referrer)
      new_query_ar = URI.decode_www_form(String(uri.query))
      new_query_ar.reject! { |(k, _v)| k == "stable_id" }
      new_query_ar << ["stable_id", @refine_filter.to_stable_id]
      uri.query = URI.encode_www_form(new_query_ar)
      @url_for_redirect = uri.to_s
    end
  end

  def stored_filters
    @refine_filter = filter
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter, id: params[:form_id])
    render partial: "stored_filters", layout: false
  end

  private

  def filter
    if stable_id
      Hammerstone.stabilizer_class('Stabilizers::UrlEncodedStabilizer').new.from_stable_id(id: stable_id)
    else
      filterClass = filter_params[:filter].constantize
      filterClass.new blueprint
    end
  end

  def filter_params
    params.permit(:filter, :stable_id, :blueprint, :form_id)
  end

  def blueprint
    return [] unless filter_params[:blueprint]
    JSON.parse(filter_params[:blueprint]).map(&:deep_symbolize_keys)
  end

  def stable_id
    filter_params[:stable_id]
  end
end
