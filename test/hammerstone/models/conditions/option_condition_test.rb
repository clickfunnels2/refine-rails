require "test_helper"
require "support/filter_test_helper"

module Hammerstone::Refine::Conditions
  describe OptionCondition do
    include FilterTestHelper

    let(:condition_under_test) {
      OptionCondition.new("option_test")
        .with_nil_option('null')
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

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (option_test varchar);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    describe 'Clause Equals' do

      it "correctly executes with one condition" do
        data = {clause: OptionCondition::CLAUSE_EQUALS, selected: "option_1"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" = 'option_1')
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'defaults to first condition if 2 are passed in' do
        data = {clause: OptionCondition::CLAUSE_EQUALS, selected: ["option_1", "option_2"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" = 'option_1')
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'handles nil condition' do
        data = {clause: OptionCondition::CLAUSE_EQUALS, selected: ["nil"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" IS NULL)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'handles special conditions' do
        data = {clause: OptionCondition::CLAUSE_EQUALS, selected: ["special"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" = 3)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end
    end

    describe 'Clause Doesn''t Equal' do

      it "correctly executes with one condition" do
        data = {clause: OptionCondition::CLAUSE_DOESNT_EQUAL, selected: "option_1"}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" != 'option_1' OR "t"."option_test" IS NULL)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'defaults to first condition if 2 are passed in' do
        data = {clause: OptionCondition::CLAUSE_DOESNT_EQUAL, selected: ["option_1", "option_2"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" != 'option_1' OR "t"."option_test" IS NULL)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'handles nil condition' do
        data = {clause: OptionCondition::CLAUSE_DOESNT_EQUAL, selected: ["null"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" IS NOT NULL)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'handles special conditions' do
        data = {clause: OptionCondition::CLAUSE_DOESNT_EQUAL, selected: ["special"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" != 3 OR "t"."option_test" IS NULL)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end
    end

    describe 'Clause In' do
      it 'works with two parameters' do
        data = {clause: OptionCondition::CLAUSE_IN, selected: ["option_1", "option_2"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" IN ('option_1', 'option_2'))
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'works with null condition' do
        data = {clause: OptionCondition::CLAUSE_IN, selected: ["option_1", "option_2", "null"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" IN ('option_1', 'option_2') OR "t"."option_test" IS NULL)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'works with special condition' do
        data = {clause: OptionCondition::CLAUSE_IN, selected: ["special"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" IN (3))
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'works with null condition only' do
        data = {clause: OptionCondition::CLAUSE_IN, selected: ["null"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE (1=0 OR "t"."option_test" IS NULL)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end
    end

    describe 'Clause Not In' do
      it 'works with two parameters' do
        data = { clause: OptionCondition::CLAUSE_NOT_IN, selected: ["option_1", "option_2"] }
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" NOT IN ('option_1', 'option_2') OR "t"."option_test" IS NULL)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'works with null condition' do
        data = {clause: OptionCondition::CLAUSE_NOT_IN, selected: ["option_1", "option_2", "null"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" NOT IN ('option_1', 'option_2') OR "t"."option_test" IS NOT NULL)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'works with special condition' do
        data = {clause: OptionCondition::CLAUSE_NOT_IN, selected: ["special"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" NOT IN (3) OR "t"."option_test" IS NULL)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end

      it 'works with null condition only' do
        data = {clause: OptionCondition::CLAUSE_NOT_IN, selected: ["null"]}
        expected_sql = <<~SQL.squish
          SELECT "t".* FROM "t" WHERE ("t"."option_test" IS NOT NULL)
        SQL
        assert_equal expected_sql, apply_condition_on_test_filter(condition_under_test, data).to_sql
      end
    end

    describe 'Configuration Object from options' do
      it 'correctly sends configurations to front end with standard syntax' do
        condition = OptionCondition.new("option_test")
                      .with_nil_option('null')
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

      it 'can handle hash shorthand' do
        skip 'does not deserialize yet'
        condition = OptionCondition.new("option_test")
                      .with_options(
                        [{
                          option_1: 'Option 1',
                          option_2: 'Option 2'
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

    describe 'Option ensurances' do
      it 'must have id' do
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

      it 'must have a display' do
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

      it 'does not allow for duplicates' do
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
  end
end
