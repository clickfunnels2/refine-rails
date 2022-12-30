module Hammerstone::Refine
  class StoredFiltersController < ApplicationController
    layout false


    def index
      @filter_class = params[:filter_class]
      @filter_form_id = params[:filter_form_id]
      @stored_filters = StoredFilter.where(filter_type: @filter_class)
      @stored_filters = instance_exec(@stored_filters, &Refine::Rails.configuration.stored_filter_scope)
    end

    def find
      @stored_filter = StoredFilter.find_by(id: params[:id])
      @refine_filter = @stored_filter.refine_filter
      @form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter)
    end

    def new
      @stored_filter = StoredFilter.new(filter_type: params[:filter_class])
      @form = Hammerstone::Refine::FilterForms::Form.new(refine_filter, id: filter_form_id)
    end

    def create
      blueprint = if params[:blueprint]
        JSON.parse(params[:blueprint]).map(&:deep_symbolize_keys)
      else
        []
      end
      refine_filter = params[:filter_class].constantize.new(blueprint)

      @stored_filter = StoredFilter.new(name: params[:name], state: refine_filter.state, filter_type: refine_filter.type, **instance_exec(&Refine::Rails.configuration.custom_stored_filter_attributes))
      @form = Hammerstone::Refine::FilterForms::Form.new(refine_filter, id: filter_form_id)

      if !@form.valid?
        # replace the filter form with errors
        render :create
      elsif !@stored_filter.save
        # replace the stored filter form
        render :new, status: :unprocessable_entity
      else
        # return to stored filters header and load the filter into the query builder
        render :find
      end
    end
  end
end