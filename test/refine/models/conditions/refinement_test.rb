require "test_helper"
require "support/refine/filter_test_helper"
require "support/refine/test_double_filter"
require "support/refine/product_contact_relationships"

module Refine::Conditions
  describe "Refinements" do
    include FilterTestHelper

    let(:text_condition) { TextCondition.new("refine_events.type") }

    around do |test|
      ActiveRecord::Base.connection.execute("CREATE TABLE refine_contacts (id bigint primary key);")
      ActiveRecord::Base.connection.execute("CREATE TABLE refine_events (id bigint primary key, refine_contact_id bigint, refine_type_id bigint, refine_product_id bigint, clicked_on datetime(6), created_at datetime(6), type varchar(256));")
      test.call
      ActiveRecord::Base.connection.execute("DROP TABLE refine_contacts, refine_events;")
    end

    describe "Date Refinement" do
      it "can set attribute as fully qualified condition" do
        condition = text_condition.refine_by_date(proc { DateCondition.new("clicked_on").attribute_is_date_with_time })
        expected_sql = <<~SQL.squish
          SELECT "refine_contacts".* FROM "refine_contacts"
          WHERE ("refine_contacts"."id" IN
          (SELECT "refine_events"."refine_contact_id" FROM "refine_events"
          WHERE ("refine_events"."type" = 'Networking Event')
          AND ("refine_events"."clicked_on"
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
        }, RefineContact.all, RefineContact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end

      it "can set attribute as string shorthand" do
        condition = text_condition.refine_by_date("clicked_on")
        expected_sql = <<~SQL.squish
          SELECT "refine_contacts".* FROM "refine_contacts"
          WHERE ("refine_contacts"."id" IN
          (SELECT "refine_events"."refine_contact_id" FROM "refine_events"
          WHERE ("refine_events"."type" = 'Networking Event')
          AND ("refine_events"."clicked_on"
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
        }, RefineContact.all, RefineContact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end

      it "defaults to created at - enable date shorthand in PHP" do
        condition = text_condition.refine_by_date

        expected_sql = <<~SQL.squish
          SELECT "refine_contacts".* FROM "refine_contacts"
          WHERE ("refine_contacts"."id" IN
          (SELECT "refine_events"."refine_contact_id" FROM "refine_events"
          WHERE ("refine_events"."type" = 'Networking Event')
          AND ("refine_events"."created_at"
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
        }, RefineContact.all, RefineContact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end

      it "can control clauses" do
        condition = text_condition.refine_by_date(proc {
                                                    DateCondition.new("clicked_on").attribute_is_date_with_time
                                                    .only_clauses([DateCondition::CLAUSE_BETWEEN])
                                                  })

        filter = TestDoubleFilter.new([])
        filter.conditions = [condition]
        refinement_clauses = filter.configuration[:conditions][0][:refinements][0][:meta][:clauses]
        expected_output =
          [{
            id: DateCondition::CLAUSE_BETWEEN,
            display: "is between",
            meta: {}
          }]

        assert_equal expected_output, refinement_clauses
      end
    end

    describe "Count Refinement" do
      it "can use refine_by_count" do
        condition = text_condition.refine_by_count
        expected_sql = <<~SQL.squish
          SELECT "refine_contacts".* FROM "refine_contacts"
          WHERE ("refine_contacts"."id" IN
          (SELECT "refine_events"."refine_contact_id" FROM "refine_events"
          WHERE ("refine_events"."type" = 'Networking Event')
          GROUP BY "refine_events"."refine_contact_id"
          HAVING (COUNT(*) BETWEEN '1' AND '10')))
        SQL
        query = apply_condition_on_test_filter(condition, {
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Networking Event",
          count_refinement: {
            clause: NumericCondition::CLAUSE_BETWEEN,
            value1: "1",
            value2: "10"
          }
        }, RefineContact.all, RefineContact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end

      it "is not impacted by attribute" do
        condition = text_condition.refine_by_count(proc {
                                                     NumericCondition.new("count_of").with_attribute("fake_attribute")
                                                   })
        expected_sql = <<~SQL.squish
          SELECT "refine_contacts".* FROM "refine_contacts"
          WHERE ("refine_contacts"."id" IN
          (SELECT "refine_events"."refine_contact_id" FROM "refine_events"
          WHERE ("refine_events"."type" = 'Networking Event')
          GROUP BY "refine_events"."refine_contact_id"
          HAVING (COUNT(*) BETWEEN '1' AND '10')))
        SQL
        query = apply_condition_on_test_filter(condition, {
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Networking Event",
          count_refinement: {
            clause: NumericCondition::CLAUSE_BETWEEN,
            value1: "1",
            value2: "10"
          }
        }, RefineContact.all, RefineContact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end

      it "can control clauses" do
        condition = text_condition.refine_by_count(proc {
                                                     NumericCondition.new("clicked_on")
                                                     .only_clauses([NumericCondition::CLAUSE_BETWEEN])
                                                   })

        filter = TestDoubleFilter.new([])
        filter.conditions = [condition]
        refinement_clauses = filter.configuration[:conditions][0][:refinements][0][:meta][:clauses]
        expected_output =
          [{
            id: NumericCondition::CLAUSE_BETWEEN,
            display: "is between",
            meta: {}
          }]

        assert_equal expected_output, refinement_clauses
      end
    end

    describe "Date and Count refinements together" do
      it "sends correct configuration to the front end" do
        condition = text_condition.refine_by_date.refine_by_count

        filter = TestDoubleFilter.new([])
        filter.conditions = [condition]

        refinement_array = filter.configuration[:conditions][0][:refinements]
        assert_equal complete_refinement_config, refinement_array
      end

      it "can use both" do
        condition = text_condition.refine_by_count.refine_by_date
        expected_sql = <<~SQL.squish
          SELECT "refine_contacts".* FROM "refine_contacts"
          WHERE ("refine_contacts"."id" IN
          (SELECT "refine_events"."refine_contact_id" FROM "refine_events"
          WHERE ("refine_events"."type" = 'Networking Event')
          AND ("refine_events"."created_at"
          BETWEEN '2021-01-01 00:00:00' AND '2021-02-01 23:59:59.999999')
          GROUP BY "refine_events"."refine_contact_id"
          HAVING (COUNT(*) BETWEEN '1' AND '10')))
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
        }, RefineContact.all, RefineContact.arel_table)
        assert_equal convert(expected_sql), query.to_sql
      end
    end

    describe "Count Refinement Has Many With 0" do
      it "adds a left joins" do
        condition = text_condition.refine_by_count
        expected_sql = <<~SQL.squish
          SELECT "refine_contacts".* FROM "refine_contacts"
          WHERE ("refine_contacts"."id" IN
          (SELECT "refine_contacts"."id"
          FROM "refine_contacts"
          LEFT OUTER JOIN
          (SELECT "refine_events"."refine_contact_id",
          COUNT(*) AS hs_refine_count_aggregate
          FROM "refine_events"
          WHERE ("refine_events"."type" = 'Networking Event')
          GROUP BY "refine_events"."refine_contact_id") interim_table ON interim_table."refine_contact_id" = "refine_contacts"."id"
          WHERE (coalesce(hs_refine_count_aggregate, 0) = '0')))
        SQL

        query = apply_condition_on_test_filter(condition, {
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Networking Event",
          count_refinement: {
            clause: NumericCondition::CLAUSE_EQUALS,
            value1: "0"
          }
        }, RefineContact.all, RefineContact.arel_table)

        assert_equal convert(expected_sql), query.to_sql
      end
    end

    describe "Type Hinting" do
      # Note: Add later
    end

    def complete_refinement_config
      [{id: "date_refinement", component: "date-condition", display: "Date Refinement",
        meta: {clauses:
          [{id: "eq", display: "on", meta: {}}, {id: "dne", display: "not on", meta: {}}, {id: "lte", display: "is on or before", meta: {}}, {id: "gte", display: "is on or after", meta: {}}, {id: "btwn", display: "is between", meta: {}},{id: "nbtwn", display: "is not between", meta: {}}, {id: "gt", display: "is more than", meta: {}}, {id: "exct", display: "is", meta: {}}, {id: "lt", display: "is less than", meta: {}}, {id: "st", display: "is set", meta: {}}, {id: "nst", display: "is not set", meta: {}}]}, refinements: []}, {id: "count_refinement", component: "numeric-condition", display: "Count Refinement", meta: {clauses: [{id: "eq", display: "is", meta: {}}, {id: "dne", display: "is not", meta: {}}, {id: "gt", display: "is greater than", meta: {}}, {id: "gte", display: "is greater than or equal to", meta: {}}, {id: "lt", display: "is less than", meta: {}}, {id: "lte", display: "is less than or equal to", meta: {}}, {id: "btwn", display: "is between", meta: {}}, {id: "nbtwn", display: "is not between", meta: {}}, {id: "st", display: "is set", meta: {}}, {id: "nst", display: "is not set", meta: {}}]}, refinements: []}]
    end
  end

  class RefinementTestDateCondition < DateCondition
  end

  class RefinementTestCountCondition < NumericCondition
  end
end
