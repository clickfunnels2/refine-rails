require "test_helper"
require "support/hammerstone/filter_test_helper"

module Hammerstone::Refine::Conditions
  describe "Belongs to test" do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE btt_notes (id bigint primary key, btt_user_id bigint);")
      ApplicationRecord.connection.execute("CREATE TABLE btt_users (id bigint primary key, name varchar(256));")
      ApplicationRecord.connection.execute("CREATE TABLE btt_phones (id bigint primary key, btt_user_id bigint);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE btt_notes, btt_users, btt_phones")
    end

    it "uses where in for belongs to" do
      query = create_filter(single_builder)
      expected_sql = <<~SQL.squish
        SELECT "btt_phones".* FROM "btt_phones"
        WHERE ("btt_phones"."btt_user_id" IN
        (SELECT "btt_users"."id" FROM "btt_users" WHERE ("btt_users"."name" = 'aaron')))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "can handle nested relationships" do
      query = create_filter(nested_builder)
      expected_sql = <<~SQL.squish
        SELECT "btt_phones".* FROM "btt_phones"
        WHERE ("btt_phones"."btt_user_id" IN
        (SELECT "btt_users"."id" FROM "btt_users" WHERE "btt_users"."id" IN
        (SELECT "btt_notes"."btt_user_id" FROM "btt_notes" WHERE ("btt_notes"."body" LIKE \'%foo%\'))))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "collapses two attributes on belongs to relationships" do
      query = create_filter(two_attributes_adjacent_blueprint)
      expected_sql = <<~SQL.squish
        SELECT "btt_phones".* FROM "btt_phones"
        WHERE ("btt_phones"."btt_user_id" IN
        (SELECT "btt_users"."id" FROM "btt_users"
        WHERE ("btt_users"."name" LIKE \'%Aaron%\') AND ("btt_users"."name" = \'Francis\')))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "collapses two attributes on belongs to when not adjacent" do
      query = create_filter(two_attributes_not_adjacent_blueprint)
      expected_sql = <<~SQL.squish
        SELECT "btt_phones".* FROM "btt_phones"
        WHERE (("btt_phones"."number" LIKE \'%214%\')
        AND ("btt_phones"."btt_user_id" IN
        (SELECT "btt_users"."id" FROM "btt_users"
        WHERE ("btt_users"."name" LIKE \'%Aaron%\') AND ("btt_users"."name" LIKE \'%Francis%\'))))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "does not mix up belongs to in groups" do
      query = create_filter(grouped_belongs_to_blueprint)
      expected_sql = <<~SQL.squish
        SELECT "btt_phones".* FROM "btt_phones"
        WHERE (("btt_phones"."btt_user_id" IN (SELECT "btt_users"."id" FROM "btt_users"
        WHERE ("btt_users"."name" LIKE '%Aaron%')
        AND ("btt_users"."name" LIKE '%Francis%'))) OR
        ("btt_phones"."btt_user_id" IN (SELECT "btt_users"."id" FROM "btt_users"
        WHERE ("btt_users"."name" LIKE '%Sean%') AND ("btt_users"."name" LIKE '%Fioritto%'))))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "Does not collapse ORs with varying depths" do
      query = create_filter(non_collapsing_blueprint)
      expected_sql = <<~SQL.squish
        SELECT
          "btt_phones".* FROM "btt_phones"
        WHERE
          (("btt_phones"."btt_user_id"
            IN (SELECT
                  "btt_users"."id"
                FROM
                  "btt_users"
                WHERE
                  ("btt_users"."name" LIKE '%Aaron%')
                  AND ("btt_users"."name" LIKE '%Francis%')))
            OR
              ("btt_phones"."btt_user_id"
              IN (SELECT
                  "btt_users"."id"
                FROM
                  "btt_users"
                WHERE
                  ("btt_users"."name" LIKE '%Sean%')))
            AND
            ("btt_phones"."btt_user_id"
              IN (SELECT "btt_users"."id"
                FROM
                  "btt_users"
                WHERE
                  ("btt_users"."name" LIKE '%Fioritto%'))))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "can handle deeply nested belongs to relationships" do
      query = create_filter(deeply_nested_blueprint)
      expected_sql = <<~SQL.squish
        SELECT "btt_phones".* FROM "btt_phones"
        WHERE ("btt_phones"."btt_user_id" IN (SELECT "btt_users"."id" FROM "btt_users"
        WHERE "btt_users"."id" IN (SELECT "btt_notes"."btt_user_id" FROM "btt_notes" WHERE ("btt_notes"."body" LIKE '%foo%'))))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "collapses first and second level belongs to" do
      query = create_filter(first_and_second_level)
      expected_sql = <<~SQL.squish
        SELECT "btt_phones".* FROM "btt_phones"
        WHERE ("btt_phones"."btt_user_id" IN
        (SELECT "btt_users"."id" FROM "btt_users"
        WHERE ("btt_users"."name" LIKE '%Aaron%')
        AND "btt_users"."id" IN (SELECT "btt_notes"."btt_user_id" FROM "btt_notes" WHERE ("btt_notes"."body" LIKE '%foo%'))))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "collapses first and second level belongs to in opposite order" do
      query = create_filter(first_and_second_level_opposite_order)
      expected_sql = <<~SQL.squish
        SELECT "btt_phones".* FROM "btt_phones"
        WHERE ("btt_phones"."btt_user_id" IN
        (SELECT "btt_users"."id" FROM "btt_users"
        WHERE "btt_users"."id" IN (SELECT "btt_notes"."btt_user_id" FROM "btt_notes"
        WHERE ("btt_notes"."body" LIKE '%foo%')) AND ("btt_users"."name" LIKE '%Aaron%')))
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "does not support refinements" do
      query = create_filter_with_refinement(single_builder_with_refinement)

      exception =
        assert_raises Hammerstone::Refine::Conditions::Errors::RelationshipError do
          query.get_query
        end
      assert_equal("Refinements are not allowed", exception.message)
    end

    def first_and_second_level_opposite_order
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("user_note_body",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "foo")
        .and
        .criterion("user_name",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "Aaron")
    end

    def first_and_second_level
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("user_name",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "Aaron")
        .and
        .criterion("user_note_body",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "foo")
    end

    def deeply_nested_blueprint
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("user_note_body",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "foo")
    end

    def non_collapsing_blueprint
      Hammerstone::Refine::Blueprints::Blueprint.new
        .group {
        criterion("user_name",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "Aaron")
          .and
          .criterion("user_name",
            clause: TextCondition::CLAUSE_CONTAINS,
            value: "Francis")
      }
        .or
        .criterion("user_name",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "Sean")
        .and
        .criterion("user_name",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "Fioritto")
    end

    def grouped_belongs_to_blueprint
      Hammerstone::Refine::Blueprints::Blueprint.new
        .group {
        criterion("user_name",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "Aaron")
          .and
          .criterion("user_name",
            clause: TextCondition::CLAUSE_CONTAINS,
            value: "Francis")
      }
        .or
        .group {
        criterion("user_name",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "Sean")
          .and
          .criterion("user_name",
            clause: TextCondition::CLAUSE_CONTAINS,
            value: "Fioritto")
      }
    end

    def two_attributes_not_adjacent_blueprint
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("user_name",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "Aaron")
        .and
        .criterion("number",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: 214)
        .and
        .criterion("user_name",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "Francis")
    end

    def two_attributes_adjacent_blueprint
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("user_name",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "Aaron")
        .and
        .criterion("user_name",
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Francis")
    end

    def nested_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("user_note_body",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "foo")
    end

    def single_builder_with_refinement
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("user_name",
          clause: TextCondition::CLAUSE_EQUALS,
          value: "aaron",
          date_refinement: {
            clause: DateCondition::CLAUSE_BETWEEN,
            date1: "2021-01-01",
            date2: "2021-02-01"
          })
    end

    def single_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("user_name",
          clause: TextCondition::CLAUSE_EQUALS,
          value: "aaron")
      # @blueprint=[{:type=>"criterion", :condition_id=>"user_name", :depth=>0, :input=>{:clause=>"eq", :value=>"Aaron"}}], @depth=0>
    end

    def create_filter(blueprint)
      BlankTestFilter.new(blueprint,
        BttPhone.all,
        [
          TextCondition.new("number"),
          TextCondition.new("user_name").with_attribute("btt_user.name"),
          TextCondition.new("user_note_body").with_attribute("btt_user.btt_notes.body")
        ],
        BttPhone.arel_table)
    end

    def create_filter_with_refinement(blueprint)
      BlankTestFilter.new(blueprint,
        BttPhone.all,
        [
          TextCondition.new("number"),
          TextCondition.new("user_name").with_attribute("btt_user.name").refine_by_date,
          TextCondition.new("user_note_body").with_attribute("btt_user.btt_notes.body")
        ],
        BttPhone.arel_table)
    end
  end

  class BttUser < ActiveRecord::Base
    self.table_name = "btt_users"
    has_one :btt_phone
    has_many :btt_notes
  end

  class BttPhone < ActiveRecord::Base
    self.table_name = "btt_phones"
    belongs_to :btt_user
  end

  class BttNote < ActiveRecord::Base
    self.table_name = "btt_notes"
    belongs_to :btt_user
  end
end
