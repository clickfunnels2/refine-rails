module Refine
  module Inspector
    def uses_or?
      return false if @blueprint.nil? || @blueprint.empty?
      @blueprint.select{|c| c[:type] == "conjunction" && c[:word] == "or"}.any?
    end

    def uses_and?
      return false if @blueprint.nil? || @blueprint.empty?
      @blueprint.select{|c| c[:type] == "conjunction" && c[:word] == "and"}.any?
    end

    def uses_condition(condition_id, using_clauses: [])
      return false if @blueprint.nil? || @blueprint.empty?
      condition = @blueprint.select{|c| c[:type] == "criterion" && c[:condition_id] == condition_id}.any?
      using_clauses = [using_clauses] unless using_clauses&.is_a?(Array)
      if(using_clauses.any?)
        condition = condition && @blueprint.select{|c| c[:type] == "criterion" && using_clauses.include?(c[:input][:clause]) }.any?
      end
      return condition
    end

    def uses_condition_at_least(condition_id, occurrences: 1)
      return false if @blueprint.nil? || @blueprint.empty?
      conditions = @blueprint.select{|c| c[:type] == "criterion" && c[:condition_id] == condition_id}
      return conditions.length >= occurrences
    end

    def uses_negative_clause?
      return false if @blueprint.nil? || @blueprint.empty?
      negative_clauses = [
        Refine::Conditions::Clauses::NOT_IN,
        Refine::Conditions::Clauses::NOT_SET,
        Refine::Conditions::Clauses::DOESNT_EQUAL,
        Refine::Conditions::Clauses::DOESNT_CONTAIN
      ]
      @blueprint.select{|c| c[:type] == "criterion" && negative_clauses.include?(c[:input][:clause])}.any?
    end

  end
end