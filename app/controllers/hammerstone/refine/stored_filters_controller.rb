module Hammerstone::Refine
  class StoredFiltersController < ApplicationController
    layout false

    before_action :set_state

    def index
      @stored_filters = StoredFilter.where(filter_type: @refine_filter_state.filter_class)
      @stored_filters = instance_exec(@stored_filters, &Refine::Rails.configuration.stored_filter_scope)
    end

    def find
      @stored_filter = StoredFilter.find_by(id: params[:id])
      @refine_filter_state.stored_filter_id = @stored_filter.id
      @refine_filter = @stored_filter.refine_filter
      @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter, id: @refine_filter_state.client_id)
    end

    def new
      @stored_filter = StoredFilter.new(filter_type: @refine_filter_state.filter_class)
    end

    def create
      @refine_filter = @refine_filter_state.refine_filter

      @stored_filter = StoredFilter.new(name: params[:name], state: @refine_filter.state, filter_type: @refine_filter.type, **instance_exec(&Refine::Rails.configuration.custom_stored_filter_attributes))
      @form = @refine_filter_state.filter_form

      if !@form.valid?
        # replace the filter form with errors
        render :create
      elsif !@stored_filter.save
        # replace the stored filter form
        render :new, status: :unprocessable_entity
      else
        # return to stored filters header and load the filter into the query builder
        @refine_filter_state.stored_filter_id = @stored_filter.id
        render :find
      end
    end

    private

    def set_state
      state_params = params.require(:hammerstone_refine_filter_state).permit(
        :blueprint_json,
        :filter_class,
        :stable_id,
        :stored_filter_id,
        :client_id,
      )

      @refine_filter_state = Hammerstone::Refine::FilterState.new(state_params)
    end
  end
end
