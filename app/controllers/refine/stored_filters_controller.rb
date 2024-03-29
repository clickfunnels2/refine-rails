module Refine
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

      # KLUDGE we need a base scope for determining if the filter is valid.
      # We set initial_queryto model.all because this filter is used just for validation
      # and is never evaluated.
      #
      # This method is a temporary workaround until we clean up input validation and
      # filter evaluation
      filter_for_model = @stored_filter.refine_filter
      model = filter_for_model.model # AR::Base subclass
      @refine_filter = @stored_filter.refine_filter(initial_query: model.all)
      @refine_filter_query = Refine::Filters::Query.new(@refine_filter)
      unless @refine_filter.valid_query?
        redirect_to refine_stored_filters_path(@refine_filter_builder.to_params),
          alert: "Sorry, that filter is not valid"
      end
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
      builder_params = params.require(:refine_filters_builder).permit(
        :blueprint_json,
        :filter_class,
        :stable_id,
        :stored_filter_id,
        :client_id,
      )

      @refine_filter_builder = Refine::Filters::Builder.new(builder_params)
    end
  end
end
