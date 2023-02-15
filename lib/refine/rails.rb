require "refine/rails/version"
require "refine/rails/engine"
require_relative "../../app/models/hammerstone/refine/stabilizers/database_stabilizer"
require_relative "../../app/models/hammerstone/refine/stabilizers/url_encoded_stabilizer"

module Refine
  module Rails
    class Config < Struct.new(:stored_filter_scope, :custom_stored_filter_attributes, :stabilizer_classes, keyword_init: true); end

    @configuration = Config.new(
      stored_filter_scope: ->(scope) { scope },
      custom_stored_filter_attributes: -> {{}},
      stabilizer_classes: {
        db: Hammerstone::Refine::Stabilizers::DatabaseStabilizer,
        url: Hammerstone::Refine::Stabilizers::UrlEncodedStabilizer
      }
    )

    module_function def configuration
      if block_given?
        yield @configuration
      else
        @configuration
      end
    end
  end
end
