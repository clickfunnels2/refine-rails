module Hammerstone::Refine
  class StoredFiltersController < ApplicationController
    layout false

    def index
      # If an id is sent in via params, it is a database stabilized filter. Redirect to show action.
      # If no id is sent it, the stable_id is sent in
      # Load filter, back (sometimes), find a filter hit this action
      return redirect_to hammerstone_refine_stored_filter_path(id: params[:id]) unless params[:id].nil?
      @stored_filter = StoredFilter.find_by(id: params[:selected_filter_id])
      # TODO if load filters is clicked but no filter is selected the widget is in an awkward state.
      @stored_filters = StoredFilter.where(filter_type: filter_class)
      @stored_filters = instance_exec(@stored_filters, &Refine::Rails.configuration.stored_filter_scope)
      @return_params = return_params
      if @stored_filter
        @back_link = hammerstone_refine_stored_filter_path(return_params.except(:selected_filter_id))
      else
        @back_link = editor_hammerstone_refine_stored_filters_path(return_params)
      end
    end

    def editor
      # Entry point for loading the viewable query builder
      return redirect_to hammerstone_refine_stored_filter_path(id: params[:id]) unless params[:id].nil?

      @refine_filter = refine_filter
      @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter)
      @return_params = return_params
      render "show"
    end

    def new
      @stored_filter = StoredFilter.find_by(id: params[:id]) || StoredFilter.new
      @stored_filter.assign_attributes filter_type: filter_class
      @stable_id = stable_id #TODO do we still need this?
      @form = Hammerstone::Refine::FilterForms::Form.new(refine_filter, id: filter_form_id)
      @back_link = editor_hammerstone_refine_stored_filters_path(return_params)
    end

    def find
      redirect_to hammerstone_refine_stored_filter_path(params[:id], return_params)
    end

    def show
      @stored_filter = StoredFilter.find_by(id: params[:id])
      # Show the refine filter for the stored filter id unless a stable id param is given
      @refine_filter = @stored_filter&.refine_filter || refine_filter
      @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter)
      @return_params = return_params.except(:id)
    end

    def create
      @stored_filter = StoredFilter.new(name: params[:name], state: refine_filter.state, filter_type: refine_filter.type, **instance_exec(&Refine::Rails.configuration.custom_stored_filter_attributes))
      @stable_id = stable_id
      @form = Hammerstone::Refine::FilterForms::Form.new(refine_filter, id: filter_form_id)
      @back_link = editor_hammerstone_refine_stored_filters_path(return_params)

      if !@form.valid?
        # replace the filter form with errors
        render :create
      elsif !@stored_filter.save
        # replace the stored filter form
        render :new, status: :unprocessable_entity
      else
        redirect_to hammerstone_refine_stored_filter_path(@stored_filter.id)
      end
    end

    private

    def filter_id
      @stored_filter&.id
    end

    def return_params
      {selected_filter_id: filter_id, id: filter_id, filter_form_id:( @form&.id || filter_form_id),
       filter: filter_class, stable_id: params[:stable_id]}.compact
    end

    def filter_class
      params[:filter]
    end

    def stable_id
      params[:stable_id]
    end

    def filter_form_id
      params[:filter_form_id]
    end

    def refine_filter
      if stable_id.present?
        Hammerstone.stabilizer_class('Stabilizers::UrlEncodedStabilizer').new.from_stable_id(id: stable_id)
      elsif filter_class
        filterClass = filter_class.constantize
        filterClass.new blueprint
      end
    end

    def blueprint
      return [] unless params[:blueprint]
      JSON.parse(params[:blueprint]).map(&:deep_symbolize_keys)
    end
  end
end
