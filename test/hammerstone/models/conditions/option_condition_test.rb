require "test_helper"
require "support/hammerstone/option_condition_filter_test_helper"

module Hammerstone::Refine::Conditions
  describe OptionCondition do
    include OptionConditionFilterTestHelper

    let(:condition_under_test) {
      OptionCondition.new("option_test")
        .with_nil_option("null")
        .with_options(
          [{
            id: "option_1",
            display: "Option 1"
          }, {
            id: "option_2",
            display: "Option 2"
          }, {
            id: "null",
            display: "Empty"
          }, {
            id: "special",
            display: "Special",
            _value: proc { 1 + 2 }
          }]
        )
    }

    let(:simple_condition) {
      OptionCondition.new("simple_option_test")
        .with_options(
          [{
            id: "1",
            display: "Awesome Product"
          }, {
            id: "2",
            display: "How to swim"
          }]
        )

    }

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE o (option_test varchar(256));")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE o;")
    end

    describe "Clause Equals" do
      it "correctly executes with one condition" do
        data = {clause: OptionCondition::CLAUSE_EQUALS, selected: ["option_1"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" = 'option_1')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "defaults to first condition if 2 are passed in" do
        data = {clause: OptionCondition::CLAUSE_EQUALS, selected: ["option_1", "option_2"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" = 'option_1')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "handles nil condition" do
        data = {clause: OptionCondition::CLAUSE_EQUALS, selected: ["null"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "handles special conditions" do
        data = {clause: OptionCondition::CLAUSE_EQUALS, selected: ["special"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" = '3')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end
    end

    describe "Clause Doesn't Equal" do
      it "correctly executes with one condition" do
        data = {clause: OptionCondition::CLAUSE_DOESNT_EQUAL, selected: ["option_1"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" != 'option_1' OR "o"."option_test" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "defaults to first condition if 2 are passed in" do
        data = {clause: OptionCondition::CLAUSE_DOESNT_EQUAL, selected: ["option_1", "option_2"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" != 'option_1' OR "o"."option_test" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "handles nil condition" do
        data = {clause: OptionCondition::CLAUSE_DOESNT_EQUAL, selected: ["null"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" IS NOT NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "handles special conditions" do
        data = {clause: OptionCondition::CLAUSE_DOESNT_EQUAL, selected: ["special"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" != '3' OR "o"."option_test" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end
    end

    describe "Clause In" do
      it "works with two parameters" do
        data = {clause: OptionCondition::CLAUSE_IN, selected: ["option_1", "option_2"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" IN ('option_1', 'option_2'))
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "works with two ints as strings" do
        data = {clause: OptionCondition::CLAUSE_IN, selected: ["1", "2"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."simple_option_test" IN ('1', '2'))
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(simple_condition, data).to_sql
      end

      it "works with null condition" do
        data = {clause: OptionCondition::CLAUSE_IN, selected: ["option_1", "option_2", "null"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" IN ('option_1', 'option_2') OR "o"."option_test" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "works with special condition" do
        data = {clause: OptionCondition::CLAUSE_IN, selected: ["special"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" IN ('3'))
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "works with null condition only" do
        data = {clause: OptionCondition::CLAUSE_IN, selected: ["null"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE (1=0 OR "o"."option_test" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end
    end

    describe "Clause Not In" do
      it "works with two parameters" do
        data = {clause: OptionCondition::CLAUSE_NOT_IN, selected: ["option_1", "option_2"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" NOT IN ('option_1', 'option_2') OR "o"."option_test" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "works with null condition" do
        data = {clause: OptionCondition::CLAUSE_NOT_IN, selected: ["option_1", "option_2", "null"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" NOT IN ('option_1', 'option_2') OR "o"."option_test" IS NOT NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "works with special condition" do
        data = {clause: OptionCondition::CLAUSE_NOT_IN, selected: ["special"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" NOT IN ('3') OR "o"."option_test" IS NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it "works with null condition only" do
        data = {clause: OptionCondition::CLAUSE_NOT_IN, selected: ["null"]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."option_test" IS NOT NULL)
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
      end
    end

    describe "Clause Set" do
      it "works with value set" do
        data = {clause: OptionCondition::CLAUSE_SET, selected:[]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."simple_option_test" IS NOT NULL OR `o`.`simple_option_test` != '')
        SQL

        assert_equal convert(expected_sql), apply_condition_on_test_filter(simple_condition, data).to_sql
      end
    end

    describe "Clause Not Set" do
      it "works with value not set" do
        data = {clause: OptionCondition::CLAUSE_NOT_SET, selected:[]}
        expected_sql = <<~SQL.squish
          SELECT "o".* FROM "o" WHERE ("o"."simple_option_test" IS NULL OR `o`.`simple_option_test` = '')
        SQL
        assert_equal convert(expected_sql), apply_condition_on_test_filter(simple_condition, data).to_sql
      end
    end

    describe "Configuration Object from options" do
      it "correctly sends configurations to front end with standard syntax" do
        condition = OptionCondition.new("option_test")
          .with_nil_option("null")
          .with_options(
            [{
              id: "option_1",
              display: "Option 1"
            }, {
              id: "option_2",
              display: "Option 2"
            }]
          )
        options = condition.to_array[:meta][:options]
        assert_equal [{
          id: "option_1",
          display: "Option 1"
        }, {
          id: "option_2",
          display: "Option 2"
        }], options
      end

      it "can handle hash shorthand" do
        skip "revisit this"
        condition = OptionCondition.new("option_test")
          .with_options(
            [{
              option_1: "Option 1",
              option_2: "Option 2"
            }]
          )
        options = condition.to_array[:meta][:options]
        assert_equal [{
          id: "option_1",
          display: "Option 1"
        }, {
          id: "option_2",
          display: "Option 2"
        }], options
      end
    end

    describe "Option ensurances" do
      it "must have id" do
        condition = OptionCondition.new("option_test")
          .with_options(
            [{
              display: "Option 1"
            }]
          )
        exception =
          assert_raises Hammerstone::Refine::Conditions::Errors::OptionError do
            condition.to_array
          end
        assert_equal("An option must have an id and a display attribute.", exception.message)
      end

      it "must have a display" do
        condition = OptionCondition.new("option_test")
          .with_options(
            [{
              id: "option_1"
            }]
          )
        exception =
          assert_raises Hammerstone::Refine::Conditions::Errors::OptionError do
            condition.to_array
          end
        assert_equal("An option must have an id and a display attribute.", exception.message)
      end

      it "does not allow for duplicates" do
        condition = OptionCondition.new("option_test")
          .with_options(
            [{
              id: "option_1",
              display: "Option 1"
            }, {
              id: "option_1",
              display: "Also Option 1"
            }]
          )
        exception =
          assert_raises Hammerstone::Refine::Conditions::Errors::OptionError do
            condition.to_array
          end
        assert_equal("Options must have unique IDs. Duplicate [\"option_1\"] found.", exception.message)
      end
    end

    describe "Option validations" do
      it "only accepts options in the set of ids" do
        condition = OptionCondition.new("option_test")
          .with_options(
            [{
              id: "option_1",
              display: "Option 1"
            }, {
              id: "option_2",
              display: "Option 2"
            }]
          )

        data = {clause: OptionCondition::CLAUSE_EQUALS, selected: ["option_7"]}
        filter = apply_condition_and_return_filter(condition, data)
        assert_equal(["Selected option_7 is not configured in options list"], filter.errors.full_messages)
      end
    end
  end
end
