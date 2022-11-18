class Hammerstone::RefineBlueprintsController < ApplicationController
  include ActionView::RecordIdentifier # for dom_id
  layout false

  def show
    @refine_filter = filter
    @form_id = filter_params[:form_id]
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter, id: @form_id)
    respond_to do |format|
      format.turbo_stream
      format.html
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
