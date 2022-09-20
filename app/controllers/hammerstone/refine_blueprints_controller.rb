class Hammerstone::RefineBlueprintsController < ApplicationController
  include ActionView::RecordIdentifier # for dom_id
  layout false

  def show
    @refine_filter = filter
    @form_id = filter_params[:form_id]
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter, id: @form_id)
    respond_to do |format|
      format.turbo_stream
    end
  end

  def create
    @refine_filter = filter
    @form_id = filter_params[:form_id]
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter, id: @form_id)

    respond_to do |format|
      format.turbo_stream do
        @form.validate!
        render :show
      end
    end
  end

  def update_stable_id
    filterClass = filter_params[:filter].constantize
    form_id = filter_params[:form_id]
    # note that here the params are coming in as a nested params hash,
    # in the show method they are a string. 
    blueprint_details = params.to_unsafe_h[:blueprint]
    filter = filterClass.new blueprint_details
    form = Hammerstone::Refine::FilterForms::Form.new(filter, id: form_id)
    if form.valid?
      filter_id = Hammerstone.stabilizer_class('Stabilizers::UrlEncodedStabilizer').new.to_stable_id(filter: filter)
      render json: { filter_id: filter_id }, status: :ok
    else
      render json: { errors: form.error_messages }, status: :unprocessable_entity
    end
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
