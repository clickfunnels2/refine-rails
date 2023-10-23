module Refine
  module Stabilize

    def automatically_stabilize?
      false
    end

    def automatic_stable_id_generator
      self.class.default_stabilizer
    end

    def to_optional_stable_id(stabilizer=nil)
      create_stable_id(stabilizer) if automatically_stabilize?
    end

    def create_stable_id(stabilizer=nil)
      make_stable_id_generator(stabilizer).new.to_stable_id(filter: self)
    end

    def make_stable_id_generator(stabilizer = nil)
      generator = stabilizer || automatic_stable_id_generator
      if generator.blank?
        raise ArgumentError.new('No stable id class set. Set using the default_stable_id_generator method')
      end
      generator
    end

  end
end