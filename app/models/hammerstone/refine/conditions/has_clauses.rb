module Hammerstone::Refine::Conditions::HasClauses

  def boot_has_clauses
    add_rules({ clause: 'required' })
    #TODO do this later in lifecycle? Send as proc?
    clauses.select{ |clause| add_rules(clause.rules) }
    with_meta({ clauses: get_clauses })
  end

  def custom_clauses
    []
  end

  def with_clauses(clauses)
    #TODO
    self
  end

  def without_clauses(clauses)
    self
    #TODO
  end

  def get_clauses #returns array of clauses

    # [{
     #   id: "eq",
     #   display: "has received",
     #   meta: [],
     # },{
     #   id: "dne",
     #   display: "has not received",
     #   meta: [],
     # }],
    clauses_serialized = []
    clauses.each do |clause|
      clauses_serialized << clause.to_array
    end
    clauses_serialized
  end
end