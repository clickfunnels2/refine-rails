require "test_helper"

module Refine::Conditions
  describe "Has Clauses" do
    before(:each) do
      DisplayRemappingTestCondition.class_variable_set :@@default_clause_display_map, {}
    end

    describe "Remap clauses at the class level" do
      it "can set default mapping" do
        DisplayRemappingTestCondition.class_variable_set :@@default_clause_display_map, {clause_0: "Statically Remapped"}
        condition = DisplayRemappingTestCondition.new("test")
        actual_clause = condition.to_array[:meta][:clauses]
        assert_equal "Statically Remapped", actual_clause[0][:display]
        assert_equal "Clause 1", actual_clause[1][:display]
      end

      it "can override default mapping" do
        DisplayRemappingTestCondition.class_variable_set :@@default_clause_display_map, {clause_0: "Statically Remapped"}
        condition = DisplayRemappingTestCondition.new("test")
        condition.remap_clause_displays({clause_0: "Instance Mapped"})
        actual_clause = condition.to_array[:meta][:clauses]
        assert_equal "Instance Mapped", actual_clause[0][:display]
        assert_equal "Clause 1", actual_clause[1][:display]
      end
    end

    describe "Remap clause display without default set" do
      it "can remap a single clause" do
        condition = DisplayRemappingTestCondition.new("test")
        condition.remap_clause_displays({clause_0: "Instance Mapped"})
        actual_clause = condition.to_array[:meta][:clauses]
        assert_equal "Instance Mapped", actual_clause[0][:display]
        assert_equal "Clause 1", actual_clause[1][:display]
      end

      it "can remap multiple clauses" do
        condition = DisplayRemappingTestCondition.new("test")
        condition.remap_clause_displays({clause_0: "Instance Mapped", clause_1: "Colleen is cool"})
        actual_clause = condition.to_array[:meta][:clauses]
        assert_equal "Instance Mapped", actual_clause[0][:display]
        assert_equal "Colleen is cool", actual_clause[1][:display]
      end
    end

    describe "No remapping" do
      it "sticks to humanized id" do
        condition = DisplayRemappingTestCondition.new("test")
        actual_clause = condition.to_array[:meta][:clauses]
        assert_equal "Clause 0", actual_clause[0][:display]
        assert_equal "Clause 1", actual_clause[1][:display]
      end
    end
  end

  class DisplayRemappingTestCondition < Condition
    include HasClauses

    def apply_condition
    end

    def component
    end

    def clauses
      [Clause.new("clause_0"),
        Clause.new("clause_1")]
    end
  end
end
