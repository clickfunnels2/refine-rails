module Hammerstone::Refine::Conditions::HasClauses

  def boot_has_clauses
    #add rules
    with_meta( {clauses: get_clauses} )
  end

  def custom_clauses
    []
  end

  def with_clauses(clauses)
    #TODO
  end

  def without_clauses(clauses)
    #TODO
  end

  def get_clauses #actually a single class

    # [{
     #   id: "eq",
     #   display: "has received",
     #   meta: [],
     # },{
     #   id: "dne",
     #   display: "has not received",
     #   meta: [],
     # }],
    # clause.map {|clause| clause.to_array}
    clauses_serialized = []
    clauses.each do |clause|
      clauses_serialized << clause.to_array
    end
    clauses_serialized

  end
end