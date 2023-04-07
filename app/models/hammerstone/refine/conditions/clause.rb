module Hammerstone::Refine::Conditions
  class Clause
    include HasMeta

    attr_reader :id, :rules
    attr_accessor :display

    def initialize(id = nil, display = nil)
      @id = id
      @display = display || id.humanize(keep_id_suffix: true).titleize
      @rules = []
    end

    def with_rules(user_defined_hash)
      @rules << (user_defined_hash)
      self
    end

    def requires_inputs(fields)
      # Coerce field to an array
      [*fields].each do |field|
        @rules << ({field: "#{field}", rule: "required", message_key: Hammerstone::Refine::Conditions::Errors::ValidationErrors::FIELD_REQUIRED})
      end
      self
    end

    def to_array
      {
        id: @id,
        display: @display,
        meta: meta
      }
    end
  end
end
