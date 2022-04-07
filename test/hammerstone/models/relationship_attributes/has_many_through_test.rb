require "test_helper"
require "support/hammerstone/filter_test_helper"

module Hammerstone::Refine::Conditions
  describe "Has Many Through Test" do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE hmtt_countries (id bigint primary key);")
      ApplicationRecord.connection.execute("CREATE TABLE hmtt_users (id bigint primary key, hmtt_country_id bigint);")
      ApplicationRecord.connection.execute("CREATE TABLE hmtt_posts (id bigint primary key, hmtt_user_id bigint, category_id bigint, name varchar(256));")
      ApplicationRecord.connection.execute("CREATE TABLE hmtt_categories (id bigint primary key);")
      ApplicationRecord.connection.execute("CREATE TABLE hmtt_owners (id bigint primary key, hmtt_country_id bigint, name varchar(256));")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE hmtt_owners, hmtt_countries, hmtt_users, hmtt_posts, hmtt_categories")
    end

    it "defaults to using active record for has many through relationships" do
      query = create_filter(single_builder)
      expected_sql = <<~SQL.squish
        SELECT
          `hmtt_countries`.*
        FROM
          `hmtt_countries`
        WHERE
          (`hmtt_countries`.`id` IN (SELECT
                `hmtt_countries`.`id`
              FROM
                `hmtt_countries`
                INNER JOIN `hmtt_users` ON `hmtt_users`.`hmtt_country_id` = `hmtt_countries`.`id`
                INNER JOIN `hmtt_posts` ON `hmtt_posts`.`hmtt_user_id` = `hmtt_users`.`id`
              WHERE
                (`hmtt_posts`.`name` = 'Foo')))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "does not collapse ands" do
      query = create_filter(double_builder)
      expected_sql = <<~SQL.squish
        SELECT "hmtt_countries".* FROM "hmtt_countries"
        WHERE (("hmtt_countries"."id" IN (SELECT
            `hmtt_countries`.`id`
          FROM
            `hmtt_countries`
            INNER JOIN `hmtt_users` ON `hmtt_users`.`hmtt_country_id` = `hmtt_countries`.`id`
            INNER JOIN `hmtt_posts` ON `hmtt_posts`.`hmtt_user_id` = `hmtt_users`.`id`
          WHERE
            (`hmtt_posts`.`name` = 'Foo')))
          AND (`hmtt_countries`.`id` IN (SELECT
            `hmtt_countries`.`id`
          FROM
            `hmtt_countries`
            INNER JOIN `hmtt_users` ON `hmtt_users`.`hmtt_country_id` = `hmtt_countries`.`id`
            INNER JOIN `hmtt_posts` ON `hmtt_posts`.`hmtt_user_id` = `hmtt_users`.`id`
          WHERE
            (`hmtt_posts`.`name` = 'Bar'))))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "cannot collapse ors" do
      query = create_filter(ors_builder)
      expected_sql = <<~SQL.squish
        SELECT "hmtt_countries".* FROM "hmtt_countries"
        WHERE (("hmtt_countries"."id" IN (SELECT
            `hmtt_countries`.`id`
          FROM
            `hmtt_countries`
            INNER JOIN `hmtt_users` ON `hmtt_users`.`hmtt_country_id` = `hmtt_countries`.`id`
            INNER JOIN `hmtt_posts` ON `hmtt_posts`.`hmtt_user_id` = `hmtt_users`.`id`
          WHERE
            (`hmtt_posts`.`name` = 'Foo')))
          OR (`hmtt_countries`.`id` IN (SELECT
            `hmtt_countries`.`id`
          FROM
            `hmtt_countries`
            INNER JOIN `hmtt_users` ON `hmtt_users`.`hmtt_country_id` = `hmtt_countries`.`id`
            INNER JOIN `hmtt_posts` ON `hmtt_posts`.`hmtt_user_id` = `hmtt_users`.`id`
          WHERE
            (`hmtt_posts`.`name` = 'Bar'))))      
      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "can mix pending relationship types" do
      query = create_filter(mixed_types_builder)
      expected_sql = <<~SQL.squish
        SELECT "hmtt_countries".* FROM "hmtt_countries"
        WHERE (("hmtt_countries"."id" IN
        (SELECT "hmtt_owners"."hmtt_country_id" FROM "hmtt_owners"
        WHERE ("hmtt_owners"."name" = 'Foo')))
        AND ("hmtt_countries"."id" IN (SELECT
            `hmtt_countries`.`id`
          FROM
            `hmtt_countries`
            INNER JOIN `hmtt_users` ON `hmtt_users`.`hmtt_country_id` = `hmtt_countries`.`id`
            INNER JOIN `hmtt_posts` ON `hmtt_posts`.`hmtt_user_id` = `hmtt_users`.`id`
          WHERE
            (`hmtt_posts`.`name` = 'Bar'))))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    def nested_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("post_category_name",
          clause: TextCondition::CLAUSE_CONTAINS,
          value: "Blog",)
    end

    def mixed_types_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("hmtt_owner_name",
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Foo",)
        .and
        .criterion("post_name",
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Bar",)
    end

    def ors_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("post_name",
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Foo",)
        .or
        .criterion("post_name",
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Bar",)
    end

    def double_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("post_name",
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Foo",)
        .and
        .criterion("post_name",
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Bar",)
    end

    def single_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion("post_name",
          clause: TextCondition::CLAUSE_EQUALS,
          value: "Foo",)
    end

    def create_filter(blueprint)
      BlankTestFilter.new(blueprint,
        HmttCountry.all,
        [
          TextCondition.new("hmtt_owner_name").with_attribute("hmtt_owner.name"),
          TextCondition.new("post_name").with_attribute("hmtt_posts.name"),
          TextCondition.new("post_category_name").with_attribute("hmtt_posts.category.name")
        ],
        HmttCountry.arel_table)
    end
  end

  class HmttUser < ActiveRecord::Base
    has_many :hmtt_posts
    belongs_to :hmtt_country
  end

  class HmttOwner < ActiveRecord::Base
  end

  class HmttCountry < ActiveRecord::Base
    has_one :hmtt_owner
    has_many :hmtt_users
    has_many :hmtt_posts, through: :hmtt_users
  end

  class HmttPost < ActiveRecord::Base
    belongs_to :hmtt_user
    belongs_to :hmtt_category
  end

  class HmttCategory < ActiveRecord::Base
    has_many :hmtt_posts
  end
end
