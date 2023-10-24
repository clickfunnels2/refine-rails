module Refine::Conditions
  module HasClauses

    def self.included(klass)
      klass.class_eval do
        mattr_accessor :default_clause_display_map, default: {}, instance_accessor: false
      end
    end

    def boot_has_clauses
      @show_clauses = {}
      add_rules({ clause: "required" })
      with_meta({ clauses: get_clauses })
      add_ensurance(ensure_clauses)
      before_validate(before_clause_validation)
    end

    def clause_display_map
      @clause_display_map ||= {}
    end

    def before_clause_validation(input = [])
      proc do |input|
        if input.present?
          current_clause = clauses.select{ |clause| clause.id == input[:clause] }
          if current_clause.present?
            add_rules(current_clause[0].rules)
          end
        end
      end
    end

    def custom_clauses
      []
    end

    def remap_clause_displays(map)
      clause_display_map.merge!(map)
      self
    end

    def only_clauses(specific_clauses)
      # Remove all clauses
      clauses.map(&:id).each {|clause_id| update_show_clauses(clause_id, false) }
      # Add specific clauses by id, not by fully qualified clause
      specific_clauses.each {|clause| update_show_clauses(clause, true) }
      self
    end

    def with_clauses(clauses_to_include)
      clauses_to_include.each {|clause| update_show_clauses(clause, true) }
      self
    end

    def without_clauses(clauses_to_exclude)
      clauses_to_exclude.each {|clause| update_show_clauses(clause, false) }
      self
    end

    def update_show_clauses(clause, value)
      @show_clauses.merge!({"#{clause}": value})
    end

    def ensure_clauses
      proc do
        clauses = get_clauses.call
        if clauses.any?
          clauses.each { |clause| ensure_clause(clause) }
        else
          errors.add(:base, I18n.t("refine.refine_blueprints.has_clauses.not_determined"))
          raise Errors::ConditionClauseError, "#{errors.full_messages}"
        end
      end
    end

    def ensure_clause(clause)
      if !clause.is_a? Clause
        errors.add(:base, I18n.t("refine.refine_blueprints.has_clauses.must_be_instance_of", instance: "#{Clause::class}"))
        raise Errors::ConditionClauseError, "#{errors.full_messages}"
      end
      if clause.id.blank? || clause.display.blank?
        errors.add(:base, I18n.t("refine.refine_blueprints.has_clauses.must_have_id_and_display"))
        raise Errors::ConditionClauseError, "#{errors.full_messages}"
      end
    end

    def get_clause_by_id(id)
      clause = get_clauses.call().find{ |clause| clause.id == id }
      raise I18n.t("refine.refine_blueprints.has_clauses.not_found", id: id) unless clause
      clause
    end

    def get_clauses
      proc do
        returned_clauses = clauses.dup
        # Clause display map takes precedence over default display map. Merge order matters.
        map = self.class.default_clause_display_map.merge(clause_display_map)
        @show_clauses.each do |clause_id, rule|
          filterable_clause_index = returned_clauses.index{ |clause| clause.id.to_sym == clause_id }
          if rule == false
            returned_clauses.delete_at(filterable_clause_index)
          elsif rule == true
            add_clause = returned_clauses.find{|clause| clause.id.to_sym == clause_id }
            returned_clauses << add_clause if !add_clause
          end
        end
        # Rewrite display if the key exists in the map.
        returned_clauses.each do |clause|
          if map.key?(clause.id.to_sym)
            clause.display = map[clause.id.to_sym]
          end
        end
        returned_clauses
      end
    end
  end
end
