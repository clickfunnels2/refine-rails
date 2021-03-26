require "test_helper"
require 'support/filter_test_helper'

module Hammerstone::Refine::Conditions
  describe 'Belongs to test' do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE btt_notes (id bigint primary key, btt_user_id bigint);")
      ApplicationRecord.connection.execute("CREATE TABLE btt_users (id bigint primary key, name varchar(255));")
      ApplicationRecord.connection.execute("CREATE TABLE btt_phones (id bigint primary key, btt_user_id bigint);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE btt_notes; DROP TABLE btt_users; DROP TABLE btt_phones;")
    end

    it 'uses where in for belongs to' do
      query = create_filter(single_builder)
      correct_sql = <<~SQL.squish
              SELECT "btt_phones".* FROM "btt_phones"
              WHERE ("btt_phones"."btt_user_id" IN
              (SELECT "btt_users"."id" FROM "btt_users" WHERE ("btt_users"."name" = 'aaron')))
              SQL
      assert_equal query.get_query.to_sql, correct_sql
    end

    it 'can handle nested relationships' do
      query = create_filter(nested_builder)
      correct_sql = <<~SQL.squish
              SELECT "btt_phones".* FROM "btt_phones"
              WHERE ("btt_phones"."btt_user_id" IN
              (SELECT "btt_users"."id" FROM "btt_users" WHERE "btt_users"."id" IN
              (SELECT "btt_notes"."btt_user_id" FROM "btt_notes" WHERE ("btt_notes"."body" ILIKE \'%foo%\'))))
              SQL
      assert_equal query.get_query.to_sql, correct_sql
    end

    it 'collapses two attributes on belongs to relationships' do
      skip 'not collapsing yet'
      query = create_filter(two_attributes_adjacent_blueprint)
      correct_sql = <<~SQL.squish
              SELECT "btt_phones".* FROM "btt_phones"
              WHERE ("btt_phones"."btt_user_id" IN
              (SELECT "btt_users"."id" FROM "btt_users"
              WHERE ("btt_users"."name" ilike \'%aaron%\') AND ("btt_users"."name" ilike \'%francis%\')))
              SQL
      assert_equal query.get_query.to_sql, correct_sql
    end

    def two_attributes_adjacent_blueprint
      Hammerstone::Refine::Blueprints::Blueprint.new
      .criterion('user_name',
        clause: TextCondition::CLAUSE_CONTAINS,
        value: 'Aaron',
      )
      .and
      .criterion('user_name',
        clause: TextCondition::CLAUSE_EQUALS,
        value: 'Francis',
      )
    end

    def nested_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
      .criterion('user_note_body',
        clause: TextCondition::CLAUSE_CONTAINS,
        value: 'foo',
      )
    end

    def single_builder
      Hammerstone::Refine::Blueprints::Blueprint.new
      .criterion('user_name',
        clause: TextCondition::CLAUSE_EQUALS,
        value: 'aaron',
      )
      # @blueprint=[{:type=>"criterion", :condition_id=>"user_name", :depth=>0, :input=>{:clause=>"eq", :value=>"Aaron"}}], @depth=0>
    end


    def create_filter(blueprint)
      BlankTestFilter.new(blueprint,
      BttPhone.all,
      [
        TextCondition.new('number'),
        TextCondition.new('user_name').with_attribute('btt_user.name'),
        TextCondition.new('user_note_body').with_attribute('btt_user.btt_notes.body')
      ],
      BttPhone.arel_table)
    end


  end

  class BttUser < ActiveRecord::Base
    self.table_name = 'btt_users'
    has_one :btt_phone
    has_many :btt_notes
  end

  class BttPhone < ActiveRecord::Base
    self.table_name = 'btt_phones'
    belongs_to :btt_user
  end

  class BttNote < ActiveRecord::Base
    self.table_name = 'btt_notes'
    belongs_to :btt_user
  end
end







