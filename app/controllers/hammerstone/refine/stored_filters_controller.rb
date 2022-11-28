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
      @return_params = return_params
      @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter)
      render "show"
    end

    def edit
      @stored_filter = StoredFilter.find(params[:id])
      @stable_id = stable_id
      @back_link = hammerstone_refine_stored_filter_path(return_params)
    end

    def update
      saved_stored_filter = StoredFilter.find(params[:id])

      if saved_stored_filter.name == params[:name]
        @stored_filter = saved_stored_filter
        @stored_filter.update(name: params[:name], state: refine_filter.state)
      else
        @stored_filter = StoredFilter.new(name: params[:name], state: refine_filter.state, filter_type: refine_filter.type, **instance_exec(&Refine::Rails.configuration.custom_stored_filter_attributes))
      end

      if @stored_filter.save
        redirect_to hammerstone_refine_stored_filter_path(id: @stored_filter.id)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def new
      @stored_filter = StoredFilter.new(name: "", state: refine_filter.state, filter_type: refine_filter.type)
      @stable_id = stable_id
      @back_link = editor_hammerstone_refine_stored_filters_path(return_params)
      @filter_form = Hammerstone::Refine::FilterForms::Form.new(refine_filter, id: filter_form_id)
    end

    def show
      @stored_filter = StoredFilter.find_by(id: params[:id])
      # Show the refine filter for the stored filter id unless a stable id param is given
      @refine_filter = refine_filter || @stored_filter&.refine_filter
      @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter)
      @return_params = return_params.except(:id)
    end

    def create
      @stored_filter = StoredFilter.new(name: params[:name], state: refine_filter.state, filter_type: refine_filter.type, **instance_exec(&Refine::Rails.configuration.custom_stored_filter_attributes))
      @stable_id = stable_id
      @back_link = editor_hammerstone_refine_stored_filters_path(return_params)
      @form_id = nil # TODO need to pass in form's UUID for rendering
      @filter_form = Hammerstone::Refine::FilterForms::Form.new(refine_filter, id: filter_form_id)

      if !refine_filter.valid?
        @replace_filter_form = true
        render :new, status: :unprocessable_entity
      elsif !@stored_filter.save
        render :new, status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def filter_id
      @stored_filter&.id
    end

    def return_params
      {selected_filter_id: filter_id, id: filter_id, filter_form_id: filter_form_id,
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
