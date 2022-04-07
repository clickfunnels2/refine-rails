require "test_helper"
require "support/hammerstone/filter_test_helper"

module Hammerstone::Refine::Conditions
  describe "Has Many Test" do
    include FilterTestHelper

    around do |test|
      ActiveRecord::Base.connection.execute("CREATE TABLE hmt_notes (id bigint primary key, hmt_user_id bigint, hmt_invoice_id bigint, body varchar(255));")
      ActiveRecord::Base.connection.execute("CREATE TABLE hmt_users (id bigint primary key, name varchar(255));")
      ActiveRecord::Base.connection.execute("CREATE TABLE hmt_invoices (id bigint primary key, hmt_user_id bigint, amount bigint);")
      test.call
      ActiveRecord::Base.connection.execute("DROP TABLE hmt_notes, hmt_users, hmt_invoices;")
    end

    it "uses where in for has many users" do
      query = create_filter(single_builder)
      expected_sql = <<~SQL.squish
        SELECT "hmt_users".* FROM "hmt_users"
        WHERE ("hmt_users"."id" IN
        (SELECT "hmt_invoices"."hmt_user_id" FROM "hmt_invoices" WHERE ("hmt_invoices"."amount" = 1)))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "does not collapse two attributes on a has_many" do
      query = create_filter(two_attributes_no_collapse)
      expected_sql = <<~SQL.squish
        SELECT "hmt_users".* FROM "hmt_users"
        WHERE (("hmt_users"."id" IN
        (SELECT "hmt_invoices"."hmt_user_id" FROM "hmt_invoices"
        WHERE ("hmt_invoices"."amount" > 1))) AND
        ("hmt_users"."id" IN
        (SELECT "hmt_invoices"."hmt_user_id" FROM "hmt_invoices"
         WHERE ("hmt_invoices"."amount" < 10))))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "can handle deeply nested has many relationships" do
      query = create_filter(deeply_nested_blueprint)
      expected_sql = <<~SQL.squish
        SELECT "hmt_users".* FROM "hmt_users"
        WHERE ("hmt_users"."id" IN
        (SELECT "hmt_invoices"."hmt_user_id" FROM "hmt_invoices"
        WHERE "hmt_invoices"."id" IN
        (SELECT "hmt_notes"."hmt_invoice_id" FROM "hmt_notes"
        WHERE ("hmt_notes"."body" LIKE '%foo%'))))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    def deeply_nested_blueprint
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("invoice_note_body",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "foo",)
    end

    def two_attributes_no_collapse
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("invoice_amount",
          clause: NumericCondition::CLAUSE_GREATER_THAN,
          value1: 1,)
        .and
        .criterion("invoice_amount",
          clause: NumericCondition::CLAUSE_LESS_THAN,
          value1: 10,)
    end

    def single_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("invoice_amount",
          clause: NumericCondition::CLAUSE_EQUALS,
          value1: 1,)
    end

    def create_filter(blueprint)
      BlankTestFilter.new(blueprint,
        HmtUser.all,
        [
          TextCondition.new("name"),
          NumericCondition.new("invoice_amount").with_attribute("hmt_invoices.amount"),
          TextCondition.new("invoice_note_body").with_attribute("hmt_invoices.hmt_notes.body")
        ],
        HmtUser.arel_table)
    end
  end

  class HmtUser < ActiveRecord::Base
    has_many :hmt_invoices
    has_many :hmt_notes
  end

  class HmtInvoice < ActiveRecord::Base
    has_many :hmt_notes
  end

  class HmtNote < ActiveRecord::Base
  end
end
