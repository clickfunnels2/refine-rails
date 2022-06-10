class Hammerstone::Refine::FilterForms::Criterion
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :depth, :integer
  attribute :criterion, :string
  attribute :condition_id, :string
  attribute :input
  attribute :word, :string
  attribute :type, :string
  attribute :position, :integer
  attribute :uid, :string

  def to_partial_path
    "hammerstone/refine_blueprints/criterion"
  end
end
