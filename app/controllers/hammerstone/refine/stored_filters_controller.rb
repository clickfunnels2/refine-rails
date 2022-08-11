module Hammerstone::Refine
  class StoredFiltersController < ApplicationController
    layout false

    def index
      # If an id is sent in via params, it is a database stabilized filter. Redirect to show action.
      # If no id is sent it, the stable_id is sent in
      # Load filter, back (sometimes), find a filter hit this action
      return redirect_to hammerstone_refine_stored_filter_path(id: params[:id]) unless params[:id].nil?
      @stored_filter = StoredFilter.find_by(id: params[:selected_filter_id])
      # Get all stored filters for this workspace to select from.
      # TODO how to set stored filters??
      # TODO if load filters is clicked but no filter is selected the widget is in an awkward state.
      @stored_filters = StoredFilter.all
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
      @save_button_active = !!stable_id
      @return_params = return_params
      @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter)
      render "show"
    end

    def update
      saved_stored_filter = StoredFilter.find(params[:id])

      if saved_stored_filter.name == params[:name]
        @stored_filter = saved_stored_filter
        @stored_filter.update(name: params[:name], state: refine_filter.state)
      else
        @stored_filter = StoredFilter.new(name: params[:name], state: refine_filter.state, filter_type: refine_filter.type)
      end
      
      if @stored_filter.save
        redirect_to hammerstone_refine_stored_filter_path(id: @stored_filter.id)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def show
      @stored_filter = StoredFilter.find_by(id: params[:id])
      # Show the refine filter for the stored filter id unless a stable id param is given
      @refine_filter = refine_filter || @stored_filter&.refine_filter
      @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter)
      @save_button_active = !!stable_id
      @return_params = return_params.except(:id)
    end

    def new
      @stored_filter = StoredFilter.new(name: "", state: refine_filter.state, filter_type: refine_filter.type)
      @back_link = editor_hammerstone_refine_stored_filters_path(return_params)
    end

    def create
      @stable_id = Hammerstone::Refine::Stabilizers::UrlEncondedStabilizer.new.to_stable_id(refine_filter)

      @stored_filter = StoredFilter.find_by(id: stable_id)
      @stored_filter ||= StoredFilter.new(name: params[:name], state: refine_filter.state, filter_type: refine_filter.type)
      @stored_filter.attributes = {name: params[:name, state: refine_filter.state]}

      @back_link = editor_hammerstone_refine_stored_filters_path(return_params)

      if @stored_filter.save
        redirect_to hammerstone_refine_stored_filter_path(id: @stored_filter.id)
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def filter_id
      @stored_filter&.id
    end

    def return_params
      {selected_filter_id: filter_id, id: filter_id,
       filter: filter_class, stable_id: params[:stable_id]}.compact
    end

    def filter_class
      params[:filter]
    end

    def stable_id
      params[:stable_id]
    end

    def refine_filter
      blueprint = if params[:blueprint]
        JSON.parse(params[:blueprint]).map(&:deep_symbolize_keys)
      else
        []
      end
      filterClass = filter_class.constantize
      filterClass.new blueprint
    end
  end
end
