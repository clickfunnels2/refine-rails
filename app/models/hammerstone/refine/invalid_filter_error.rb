class Hammerstone::Refine::InvalidFilterError < StandardError
  attr_reader :filter

  def initialize(msg="Filter is invalid", filter: nil)
    @msg = msg
    filter = filter
  end
end
