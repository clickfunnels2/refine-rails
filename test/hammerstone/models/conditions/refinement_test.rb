require "test_helper"
require "support/hammerstone/filter_test_helper"
require "support/hammerstone/test_filter"

module Hammerstone::Refine::Conditions
  describe "Refinements" do
    include FilterTestHelper

    let(:text_condition) { TextCondition.new("events.type") }

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE c (id bigint primary key);")
      ApplicationRecord.connection.execute("CREATE TABLE e (id bigint primary key, contact_id bigint, clicked_on datetime(6), created_at datetime(6), type varchar(256));")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE c, e")
    end

    describe "Date Refinement" do
      it "can set attribute as fully qualified condition" do
        condition = text_condition.refine_by_date(proc { DateCondition.new("clicked_on").attribute_is_date_with_time })
        expected_sql = <<~SQL.squish
          SELECT "c".* FROM "c"
          WHERE ("c"."id" IN
          (SELECT "e"."contact_id" FROM "e"
          WHERE ("e"."type" = 'Networking Event')
          AND ("e"."clicked_on"
          BETWEEN '2021-01-01 00:00:00' AND '2021-02-01 23:59:59.999999')))
        SQL
        query = apply_condition_on_test_filter(condition, {
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Networking Event",
          date_refinement: {
            clause: DateCondition::CLAUSE_BETWEEN,
            date1: "2021-01-01",
            date2: "2021-02-01"
          }
        }, Contact.all, Contact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end

      it "can set attribute as string shorthand" do
        condition = text_condition.refine_by_date("clicked_on")
        expected_sql = <<~SQL.squish
          SELECT "c".* FROM "c"
          WHERE ("c"."id" IN
          (SELECT "e"."contact_id" FROM "e"
          WHERE ("e"."type" = 'Networking Event')
          AND ("e"."clicked_on"
          BETWEEN '2021-01-01 00:00:00' AND '2021-02-01 23:59:59.999999')))
        SQL
        query = apply_condition_on_test_filter(condition, {
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Networking Event",
          date_refinement: {
            clause: DateCondition::CLAUSE_BETWEEN,
            date1: "2021-01-01",
            date2: "2021-02-01"
          }
        }, Contact.all, Contact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end

      it "defaults to created at - enable date shorthand in PHP" do
        condition = text_condition.refine_by_date

        expected_sql = <<~SQL.squish
          SELECT "c".* FROM "c"
          WHERE ("c"."id" IN
          (SELECT "e"."contact_id" FROM "e"
          WHERE ("e"."type" = 'Networking Event')
          AND ("e"."created_at"
          BETWEEN '2021-01-01 00:00:00' AND '2021-02-01 23:59:59.999999')))
        SQL

        query = apply_condition_on_test_filter(condition, {
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Networking Event",
          date_refinement: {
            clause: DateCondition::CLAUSE_BETWEEN,
            date1: "2021-01-01",
            date2: "2021-02-01"
          }
        }, Contact.all, Contact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end

      it "can control clauses" do
        condition = text_condition.refine_by_date(proc {
                                                    DateCondition.new("clicked_on").attribute_is_date_with_time
                                                    .only_clauses([DateCondition::CLAUSE_BETWEEN])
                                                  })

        filter = TestFilter.new([])
        filter.conditions = [condition]
        refinement_clauses = filter.configuration[:conditions][0][:refinements][0][:meta][:clauses]
        expected_output =
          [{
            id: DateCondition::CLAUSE_BETWEEN,
            display: "Is Between",
            meta: {}
          }]

        assert_equal expected_output, refinement_clauses
      end
    end

    describe "Count Refinement" do
      it "can use refine_by_count" do
        condition = text_condition.refine_by_count
        expected_sql = <<~SQL.squish
          SELECT "c".* FROM "c"
          WHERE ("c"."id" IN
          (SELECT "e"."contact_id" FROM "e"
          WHERE ("e"."type" = 'Networking Event')
          GROUP BY "e"."contact_id"
          HAVING COUNT(*) BETWEEN '1' AND '10'))
        SQL
        query = apply_condition_on_test_filter(condition, {
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Networking Event",
          count_refinement: {
            clause: NumericCondition::CLAUSE_BETWEEN,
            value1: "1",
            value2: "10"
          }
        }, Contact.all, Contact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end

      it "is not impacted by attribute" do
        condition = text_condition.refine_by_count(proc {
                                                     NumericCondition.new("count_of").with_attribute("fake_attribute")
                                                   })
        expected_sql = <<~SQL.squish
          SELECT "c".* FROM "c"
          WHERE ("c"."id" IN
          (SELECT "e"."contact_id" FROM "e"
          WHERE ("e"."type" = 'Networking Event')
          GROUP BY "e"."contact_id"
          HAVING COUNT(*) BETWEEN '1' AND '10'))
        SQL
        query = apply_condition_on_test_filter(condition, {
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Networking Event",
          count_refinement: {
            clause: NumericCondition::CLAUSE_BETWEEN,
            value1: "1",
            value2: "10"
          }
        }, Contact.all, Contact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end

      it "can control clauses" do
        condition = text_condition.refine_by_count(proc {
                                                     NumericCondition.new("clicked_on")
                                                     .only_clauses([NumericCondition::CLAUSE_BETWEEN])
                                                   })

        filter = TestFilter.new([])
        filter.conditions = [condition]
        refinement_clauses = filter.configuration[:conditions][0][:refinements][0][:meta][:clauses]
        expected_output =
          [{
            id: NumericCondition::CLAUSE_BETWEEN,
            display: "Is Between",
            meta: {}
          }]

        assert_equal expected_output, refinement_clauses
      end
    end

    describe "Date and Count refinements together" do
      it "sends correct configuration to the front end" do
        condition = text_condition.refine_by_date.refine_by_count

        filter = TestFilter.new([])
        filter.conditions = [condition]

        refinement_array = filter.configuration[:conditions][0][:refinements]
        assert_equal complete_refinement_config, refinement_array
      end

      it "can use both" do
        condition = text_condition.refine_by_count.refine_by_date
        expected_sql = <<~SQL.squish
          SELECT "c".* FROM "c"
          WHERE ("c"."id" IN
          (SELECT "e"."contact_id" FROM "e"
          WHERE ("e"."type" = 'Networking Event')
          AND ("e"."created_at"
          BETWEEN '2021-01-01 00:00:00' AND '2021-02-01 23:59:59.999999')
          GROUP BY "e"."contact_id"
          HAVING COUNT(*) BETWEEN '1' AND '10'))
        SQL
        query = apply_condition_on_test_filter(condition, {
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Networking Event",
          count_refinement: {
            clause: NumericCondition::CLAUSE_BETWEEN,
            value1: "1",
            value2: "10"
          },
          date_refinement: {
            clause: DateCondition::CLAUSE_BETWEEN,
            date1: "2021-01-01",
            date2: "2021-02-01"
          }
        }, Contact.all, Contact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end
    end

    describe "Count Refinement Has Many With 0" do
      it "adds a left joins" do
        condition = text_condition.refine_by_count
        expected_sql = <<~SQL.squish
          SELECT "c".* FROM "c"
          WHERE ("c"."id" IN
          (SELECT "c"."id"
          FROM "c"
          LEFT OUTER JOIN
          (SELECT "e"."contact_id",
          COUNT(*) AS hs_refine_count_aggregate
          FROM "e"
          WHERE ("e"."type" = 'Networking Event')
          GROUP BY "e"."contact_id") interim_table ON interim_table."contact_id" = "c"."id"
          WHERE coalesce(hs_refine_count_aggregate, 0) = '0'))
        SQL

        query = apply_condition_on_test_filter(condition, {
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Networking Event",
          count_refinement: {
            clause: NumericCondition::CLAUSE_EQUALS,
            value1: "0"
          }
        }, Contact.all, Contact.arel_table)

        assert_equal convert(expected_sql), query.to_sql
      end
    end

    describe "Type Hinting" do
      # Note: Add later
    end

    def complete_refinement_config
      [{id: "date_refinement", component: "date-condition", display: "Date Refinement", meta: {clauses: [{id: "eq", display: "Is Equal To", meta: {}}, {id: "dne", display: "Is Not Equal To", meta: {}}, {id: "lte", display: "Is On or Before", meta: {}}, {id: "gte", display: "Is On or After", meta: {}}, {id: "btwn", display: "Is Between", meta: {}}, {id: "gt", display: "Is More Than", meta: {}}, {id: "exct", display: "Is Exactly", meta: {}}, {id: "lt", display: "Is Less Than", meta: {}}, {id: "st", display: "Is Set", meta: {}}, {id: "nst", display: "Is Not Set", meta: {}}]}, refinements: []}, {id: "count_refinement", component: "numeric-condition", display: "Count Refinement", meta: {clauses: [{id: "eq", display: "Is Equal To", meta: {}}, {id: "dne", display: "Is Not Equal To", meta: {}}, {id: "gt", display: "Is Greater Than", meta: {}}, {id: "gte", display: "Is Greater Than Or Equal To", meta: {}}, {id: "lt", display: "Is Less Than", meta: {}}, {id: "lte", display: "Is Less Than Or Equal To", meta: {}}, {id: "btwn", display: "Is Between", meta: {}}, {id: "nbtwn", display: "Is Not Between", meta: {}}, {id: "st", display: "Is Set", meta: {}}, {id: "nst", display: "Is Not Set", meta: {}}]}, refinements: []}]
    end
  end

  class Contact < ActiveRecord::Base
    has_many :events
    self.table_name = "c"
  end

  class Event < ActiveRecord::Base
    belongs_to :contacts
    self.table_name = "e"
  end

  class RefinementTestDateCondition < DateCondition
  end

  class RefinementTestCountCondition < NumericCondition
  end
end
