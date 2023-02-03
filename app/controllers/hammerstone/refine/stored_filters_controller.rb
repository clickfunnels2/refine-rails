module Hammerstone::Refine
  class StoredFiltersController < ApplicationController
    layout false

    before_action :set_builder

    def index
      @stored_filters = StoredFilter.where(filter_type: @refine_filter_builder.filter_class)
      @stored_filters = instance_exec(@stored_filters, &Refine::Rails.configuration.stored_filter_scope)
    end

    def find
      @stored_filter = StoredFilter.find_by(id: params[:id])
      @refine_filter_builder.stored_filter_id = @stored_filter.id
      @refine_filter = @stored_filter.refine_filter
      @refine_filter_query = Hammerstone::Refine::Filters::Query.new(@refine_filter)
    end

    def new
      @stored_filter = StoredFilter.new(filter_type: @refine_filter_builder.filter_class)
    end

    def create
      @refine_filter = @refine_filter_builder.refine_filter

      @stored_filter = StoredFilter.new(name: params[:name], state: @refine_filter.state, filter_type: @refine_filter.type, **instance_exec(&Refine::Rails.configuration.custom_stored_filter_attributes))
      @refine_filter_query = @refine_filter_builder.query

      if !@refine_filter_query.valid?
        # replace the filter form with errors
        render :create
      elsif !@stored_filter.save
        # replace the stored filter form
        render :new, status: :unprocessable_entity
      else
        # return to stored filters header and load the filter into the query builder
        @refine_filter_builder.stored_filter_id = @stored_filter.id
        render :find
      end
    end

    private

    def set_builder
      builder_params = params.require(:hammerstone_refine_filters_builder).permit(
        :blueprint_json,
        :filter_class,
        :stable_id,
        :stored_filter_id,
        :client_id,
      )

      @refine_filter_builder = Hammerstone::Refine::Filters::Builder.new(builder_params)
    end
  end
end
