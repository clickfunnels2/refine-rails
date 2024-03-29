module Refine::Conditions
  class Clause
    include HasMeta

    attr_reader :id, :rules
    attr_accessor :display

    I18N_PREFIX = "refine.refine_blueprints.clause."

    def initialize(id = nil, display = nil)
      @id = id
      @display = display || id.humanize(keep_id_suffix: true).titleize
      @rules = {}
      @messages
    end

    def with_rules(user_defined_hash)
      @rules.merge!(user_defined_hash)
      self
    end

    def requires_inputs(fields)
      # Coerce field to an array
      [*fields].each do |field|
        @rules.merge!({"#{field}": I18n.t("#{I18N_PREFIX}required")})
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
