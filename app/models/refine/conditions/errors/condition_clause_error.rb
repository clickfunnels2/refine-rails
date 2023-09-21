class Refine::Conditions::Errors::ConditionClauseError < StandardError
  attr_reader :errors
  def initialize(message, errors: [])
    @errors = errors
    super(message)
  end
end
