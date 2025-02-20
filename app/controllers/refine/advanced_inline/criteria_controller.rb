class Refine::AdvancedInline::CriteriaController < ApplicationController
  layout false
  before_action :set_refine_filter
  # List available conditions for new criteria
  # Carries position and index forward
  def index
    @criterion = Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter))
    @conditions = @refine_filter.instantiated_conditions
  end

  # Show the form to add a new criteria
  def new
    @criterion = Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter))
    respond_to do |format|
      # render a turbo_stream so that we can render inputs and forms in separate areas of the page
      # in case we're nested inside a form
      format.turbo_stream
    end
  end

  # Create a new criterion
  def create
    @criterion = Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter))
    blueprint = @refine_filter.blueprint

    Refine::Filters::BlueprintEditor
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
        format.turbo_stream { render :new }
      end
    end
  end

  # show the form to edit an existing criterion
  def edit
    @criterion = Refine::Inline::Criterion
      .groups_from_filter(@refine_filter, **criterion_params.slice(:client_id, :stable_id))
      .flatten
      .detect { |c| c.position.to_s == params[:id] }

    @criterion.attributes = criterion_params
    respond_to do |format|
      # render a turbo_stream so that we can render inputs and forms in separate areas of the page
      # in case we're nested inside a form
      format.turbo_stream
    end
  end

  # update an exsiting criterion
  def update
    @criterion = Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter)) 
    Refine::Filters::BlueprintEditor
      .new(@refine_filter.blueprint)
      .update(params[:id].to_i, criterion: @criterion.to_blueprint_node)

    @error_messages = filter_error_messages(@refine_filter)
    if @error_messages.none?
        handle_filter_update(@refine_filter.to_stable_id)
    else
      respond_to do |format|
        format.turbo_stream { render :edit }
      end
    end
  end

  # remove an existing criterion
  def destroy
    @criterion = Refine::Inline::Criterion
      .groups_from_filter(@refine_filter, **criterion_params.slice(:client_id, :stable_id))
      .flatten
      .detect { |c| c.position.to_s == params[:id] }

    Refine::Filters::BlueprintEditor
      .new(@refine_filter.blueprint)
      .delete(params[:id].to_i)

    handle_filter_update(@refine_filter.to_stable_id)
  end

  def clear
    @refine_filter.clear_blueprint!
    @criterion = Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter))
    handle_filter_update()
  end

  def merge_groups
    @criterion = Refine::Inline::Criterion.new(criterion_params.merge(refine_filter: @refine_filter)) 
    Refine::Filters::BlueprintEditor
    .new(@refine_filter.blueprint)
    .change_conjunction(criterion_params[:position].to_i - 1, "and")

    handle_filter_update(@refine_filter.to_stable_id)
  end

  private

  def set_refine_filter
    @refine_filter ||= Refine::Rails.configuration.stabilizer_classes[:url]
      .new
      .from_stable_id(id: criterion_params[:stable_id])
  end

  def criterion_params
    params.require(:refine_inline_criterion).permit(
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
        ],
        date_refinement_attributes: [
          :clause,
          :date1,
          :date2,
          :days,
          :modifier
        ]
      ]
    )
  end

  # either directly redirect or emit a `filter-submit-success` event
  def handle_filter_update(stable_id=nil)
    # update_stable_id in url
    uri = URI(request.referrer)
    new_query_ar = URI.decode_www_form(String(uri.query))
    new_query_ar.reject! { |(k, _v)| k == "stable_id" }
    if stable_id
      new_query_ar << ["stable_id", stable_id]
    end
    uri.query = URI.encode_www_form(new_query_ar)

    respond_to do |format|
      format.turbo_stream do
        @refine_stable_id = stable_id
        @url_for_redirect = uri
        @refine_client_id = @criterion.client_id
        render :create
      end
      format.html do 
        redirect_to uri.to_s 
      end
    end
  end

  def filter_valid?(refine_filter)
    Refine::Inline::Criterion
      .groups_from_filter(refine_filter, **criterion_params.slice(:client_id, :stable_id))
      .flatten
      .all?(&:valid?)
  end

  def filter_error_messages(refine_filter)
    criteria = Refine::Inline::Criterion
      .groups_from_filter(refine_filter, **criterion_params.slice(:client_id, :stable_id))
      .flatten

    criteria.each(&:validate!)
    criteria.flat_map {|c| c.errors.full_messages }
  end
end
