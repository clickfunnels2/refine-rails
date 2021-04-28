require "test_helper"
require 'support/filter_test_helper'

module Hammerstone::Refine::Conditions
  describe 'Has Many Through Test' do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE countries (id bigint primary key);")
      ApplicationRecord.connection.execute("CREATE TABLE hmtt_users (id bigint primary key, country_id bigint);")
      ApplicationRecord.connection.execute("CREATE TABLE posts (id bigint primary key, hmtt_user_id bigint, category_id bigint, name varchar );")
      ApplicationRecord.connection.execute("CREATE TABLE categories (id bigint primary key);")
      ApplicationRecord.connection.execute("CREATE TABLE owners (id bigint primary key, country_id bigint, name varchar);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE owners; DROP TABLE countries; DROP TABLE hmtt_users; DROP TABLE posts; DROP TABLE categories")
    end

    it 'uses where in and join for has many through' do
      query = create_filter(single_builder)
      correct_sql = <<~SQL.squish
            SELECT "countries".* FROM "countries"
            WHERE ("countries"."id" IN
            (SELECT "hmtt_users"."country_id" FROM "hmtt_users"
            INNER JOIN "posts" ON "hmtt_users"."id" = "posts"."hmtt_user_id"
            WHERE ("posts"."name" = 'Foo')))
      SQL
      assert_equal query.get_query.to_sql, correct_sql
    end

    it 'cannot collapse ands' do
      query = create_filter(double_builder)
      correct_sql = <<~SQL.squish
            SELECT "countries".* FROM "countries"
            WHERE (("countries"."id" IN
            (SELECT "hmtt_users"."country_id" FROM "hmtt_users"
            INNER JOIN "posts" ON "hmtt_users"."id" = "posts"."hmtt_user_id"
            WHERE ("posts"."name" = 'Foo')))
            AND ("countries"."id" IN
            (SELECT "hmtt_users"."country_id" FROM "hmtt_users"
            INNER JOIN "posts" ON "hmtt_users"."id" = "posts"."hmtt_user_id"
            WHERE ("posts"."name" = 'Bar'))))
      SQL
      assert_equal query.get_query.to_sql, correct_sql
    end

    it 'cannot collapse ors' do
      query = create_filter(ors_builder)
      correct_sql = <<~SQL.squish
            SELECT "countries".* FROM "countries"
            WHERE (("countries"."id" IN
            (SELECT "hmtt_users"."country_id" FROM "hmtt_users"
            INNER JOIN "posts" ON "hmtt_users"."id" = "posts"."hmtt_user_id"
            WHERE ("posts"."name" = 'Foo')))
            OR ("countries"."id" IN
            (SELECT "hmtt_users"."country_id" FROM "hmtt_users"
            INNER JOIN "posts" ON "hmtt_users"."id" = "posts"."hmtt_user_id"
            WHERE ("posts"."name" = 'Bar'))))
      SQL
      assert_equal query.get_query.to_sql, correct_sql
    end

    it 'can mix pending relationship types' do
      query = create_filter(mixed_types_builder)
      correct_sql = <<~SQL.squish
            SELECT "countries".* FROM "countries"
            WHERE (("countries"."id" IN
            (SELECT "owners"."country_id" FROM "owners"
            WHERE ("owners"."name" = 'Foo')))
            AND ("countries"."id" IN
            (SELECT "hmtt_users"."country_id" FROM "hmtt_users"
            INNER JOIN "posts" ON "hmtt_users"."id" = "posts"."hmtt_user_id"
            WHERE ("posts"."name" = 'Bar'))))
      SQL
      assert_equal query.get_query.to_sql, correct_sql
    end

    def nested_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion('post_category_name',
          clause: TextCondition::CLAUSE_CONTAINS,
          value: 'Blog',
        )
    end

    def mixed_types_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion('owner_name',
          clause: TextCondition::CLAUSE_EQUALS,
          value: 'Foo',
        )
        .and
        .criterion('post_name',
          clause: TextCondition::CLAUSE_EQUALS,
          value: 'Bar',
        )
      end

    def ors_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion('post_name',
          clause: TextCondition::CLAUSE_EQUALS,
          value: 'Foo',
        )
        .or
        .criterion('post_name',
          clause: TextCondition::CLAUSE_EQUALS,
          value: 'Bar',
        )
    end


    def double_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
        .criterion('post_name',
          clause: TextCondition::CLAUSE_EQUALS,
          value: 'Foo',
        )
        .and
        .criterion('post_name',
          clause: TextCondition::CLAUSE_EQUALS,
          value: 'Bar',
        )
    end

    def single_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
      .criterion('post_name',
        clause: TextCondition::CLAUSE_EQUALS,
        value: 'Foo',
      )
    end

    def create_filter(blueprint)
      BlankTestFilter.new(blueprint,
      Country.all,
      [
        TextCondition.new('owner_name').with_attribute('owner.name'),
        TextCondition.new('post_name').with_attribute('posts.name'),
        TextCondition.new('post_category_name').with_attribute('posts.category.name')
      ],
      Country.arel_table)
    end
  end

  class HmttUser < ActiveRecord::Base
    has_many :posts
    belongs_to :country
  end

  class Owner < ActiveRecord::Base
  end

  class Country < ActiveRecord::Base
    has_one :owner
    has_many :hmtt_users
    has_many :posts, through: :hmtt_users
  end

  class Post < ActiveRecord::Base
    belongs_to :hmtt_user
    belongs_to :category
  end

  class Category < ActiveRecord::Base
    has_many :posts
  end
end

