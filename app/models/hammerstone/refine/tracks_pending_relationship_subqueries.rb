module Hammerstone::Refine
  module TracksPendingRelationshipSubqueries

    def pending_relationship_subquery_depth
      @pending_relationship_subquery_depth ||= []
    end

    def pending_relationship_subqueries
      @pending_relationship_subqueries ||= {}
    end

    def add_to_stack(variable, obj)
      variable.push(obj)
    end

    def set_pending_relationship(relation, instance)
      add_to_stack(pending_relationship_subquery_depth, relation)
      pending_relationship_subqueries.merge!({ relation: instance })
    end

    def get_current_relationship

    end

    def get_pending_relationship_subquery
      nil
    end
  end
end