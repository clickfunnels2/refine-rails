require "refine/rails/version"
require "refine/rails/engine"

module Refine
  module Rails
    class Config < Struct.new(:stored_filter_scope, keyword_init: true); end

    @configuration = Config.new(
      stored_filter_scope: ->(scope) { scope }
    )
    module_function def configuration
      @configuration
    end
  end
end
