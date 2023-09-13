class Hammerstone::Refine::Inline::CriteriaController < ApplicationController
  layout false
  before_action :set_refine_filter

  # List available conditions for new criteria
  # Carries position and index forward
  def index
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter))
    @conditions = @refine_filter.instantiated_conditions
  end

  # Show the form to add a new criteria
  def new
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter))
    respond_to do |format|
      # render a turbo_stream so that we can render inputs and forms in separate areas of the page
      # in case we're nested inside a form
      format.turbo_stream
    end
  end

  # Create a new criterion
  def create
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter))
    blueprint = @refine_filter.blueprint

    Hammerstone::Refine::Filters::BlueprintEditor
      .new(@refine_filter.blueprint)
      .add(
        position: @criterion.position.to_i,
        conjunction: @criterion.conjunction,
        criterion: @criterion.to_blueprint_node
      )

    @error_messages = filter_error_messages(@refine_filter)
    if @error_messages.none?
      handle_filter_update(@refine_filter.to_stable_id)
    else
      respond_to do |format|
        formt.turbo_stream { render :new }
      end
    end
  end

  # show the form to edit an existing criterion
  def edit
    @criterion = Hammerstone::Refine::Inline::Criterion
      .groups_from_filter(@refine_filter, **criterion_params.slice(:client_id, :stable_id))
      .flatten
      .detect { |c| c.position.to_s == params[:id] }

    @criterion.attributes = criterion_params
  end

  # update an exsiting criterion
  def update
    @criterion = Hammerstone::Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter)) 
    Hammerstone::Refine::Filters::BlueprintEditor
      .new(@refine_filter.blueprint)
      .update(params[:id].to_i, criterion: @criterion.to_blueprint_node)

    @error_messages = filter_error_messages(@refine_filter)
    if @error_messages.none?
        handle_filter_update(@refine_filter.to_stable_id)
    else
      render turbo_stream: turbo_stream.update(
        @criterion,
        self.class.render("edit", assigns: {criterion: @criterion, refine_filter: @refine_filter, error_messages: @error_messages})
      )
    end
  end

  # remove an existing criterion
  def destroy
    @criterion = Hammerstone::Refine::Inline::Criterion
      .groups_from_filter(@refine_filter, **criterion_params.slice(:client_id, :stable_id))
      .flatten
      .detect { |c| c.position.to_s == params[:id] }

    Hammerstone::Refine::Filters::BlueprintEditor
      .new(@refine_filter.blueprint)
      .delete(params[:id].to_i)

    handle_filter_update(@refine_filter.to_stable_id)
  end

  private

  def set_refine_filter
    @refine_filter ||= Refine::Rails.configuration.stabilizer_classes[:url]
      .new
      .from_stable_id(id: criterion_params[:stable_id])
  end

  def criterion_params
    params.require(:hammerstone_refine_inline_criterion).permit(
      :stable_id,
      :client_id,
      :condition_id,
      :position,
      :conjunction,
      input_attributes: [
        :clause,
        :date1,
        :date2,
        :days,
        :modifier,
        :selected,
        :value,
        :value1,
        :value2,
        selected: [],
        count_refinement_attributes: [
          :clause,
          :value1,
          :value2
        ]
      ]
    )
  end

  # either directly redirect or emit a `filter-submit-success` event
  def handle_filter_update stable_id
    # update_stable_id in url
    uri = URI(request.referrer)
    new_query_ar = URI.decode_www_form(String(uri.query))
    new_query_ar.reject! { |(k, _v)| k == "stable_id" }
    new_query_ar << ["stable_id", stable_id]
    uri.query = URI.encode_www_form(new_query_ar)

    respond_to do |format|
      format.turbo_stream do
        @refine_stable_id = stable_id
        @url_for_redirect = uri
        @refine_client_id = @criterion.client_id
        render :create
      end
      format.html {redirect_to uri.to_s }
    end
  end

  def filter_valid?(refine_filter)
    Hammerstone::Refine::Inline::Criterion
      .groups_from_filter(refine_filter, **criterion_params.slice(:client_id, :stable_id))
      .flatten
      .all?(&:valid?)
  end

  def filter_error_messages(refine_filter)
    criteria = Hammerstone::Refine::Inline::Criterion
      .groups_from_filter(refine_filter, **criterion_params.slice(:client_id, :stable_id))
      .flatten

    criteria.each(&:validate!)
    criteria.flat_map {|c| c.errors.full_messages }
  end
end
