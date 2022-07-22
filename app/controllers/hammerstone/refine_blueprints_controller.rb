class Hammerstone::RefineBlueprintsController < ApplicationController
  layout false
  include Hammerstone::RefineHelper # for create_id

  def show
    @refine_filter = filter
    @id_suffix = filter_params[:id_suffix]
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter)
  end

  def create
    @refine_filter = filter
    @id_suffix = filter_params[:id_suffix]
    @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter)

    if @form.valid?
      status = :ok
      payload = {}
    else
      status = :unprocessable_entity
      payload = {
        action: "replace",
        target: create_id("hammerstone_refine_query"),
        template: self.class.render(
          partial: "hammerstone/refine_blueprints/query",
          assigns: {refine_filter: @refine_filter, id_suffix: @id_suffix, form: @form}
        )
      }
    end

    render json: payload, status: status
  end

  def update_stable_id
    filterClass = filter_params[:filter].constantize
    # TODO can't re-use blueprint method here b/c the params are coming in as a nested params hash, 
    # in the show method they are a string. 
    blueprint_details = params.to_unsafe_h[:blueprint]
    filter = filterClass.new blueprint_details
    filter_id = Hammerstone.stabilizer_class('Stabilizers::UrlEncodedStabilizer').new.to_stable_id(filter: filter)
    render json: { filter_id: filter_id }, status: :ok
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
    params.permit(:filter, :stable_id, :blueprint, :id_suffix)
  end

  def blueprint
    return [] unless filter_params[:blueprint]
    JSON.parse(filter_params[:blueprint]).map(&:deep_symbolize_keys)
  end

  def stable_id
    filter_params[:stable_id]
  end
end
