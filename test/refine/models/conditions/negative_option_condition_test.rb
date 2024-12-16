require "test_helper"
require "support/refine/filter_test_helper"

module Refine::Conditions
  describe "Has Many Through Test" do
    include FilterTestHelper

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE contacts (id bigint primary key);")
      ApplicationRecord.connection.execute("CREATE TABLE contacts_applied_tags (id bigint primary key, contact_id bigint, tag_id bigint);")
      ApplicationRecord.connection.execute("CREATE TABLE contacts_tags (id bigint primary key);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE contacts, contacts_applied_tags, contacts_tags")
    end

    it "properly handles negative option conditions" do 
      query = create_filter(does_not_contain_option_condition)
      expected_sql = <<~SQL.squish
        SELECT
          `contacts`.*
        FROM
          `contacts`
        WHERE (`contacts`.`id` NOT IN (SELECT
                `contacts`.`id` FROM `contacts`
                INNER JOIN `contacts_applied_tags` ON `contacts_applied_tags`.`contact_id` = `contacts`.`id`
                INNER JOIN `contacts_tags` ON `contacts_tags`.`id` = `contacts_applied_tags`.`tag_id`
              WHERE (`contacts_tags`.`id` IN (1))))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "properly handles negative option conditions with through id set" do 
      # TODO 
      query = create_filter_with_through_id(does_not_contain_option_condition)
      expected_sql = <<~SQL.squish
        SELECT
          `contacts`.*
        FROM
          `contacts`
        WHERE (`contacts`.`id` NOT IN (SELECT
                `contacts_applied_tags`.`contact_id` FROM `contacts_applied_tags`
              WHERE (`contacts_applied_tags`.`tag_id` IN (1))))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    it "properly handles negative option conditions with through id set and forced index" do 
      # TODO 
      query = create_filter_with_through_id_forced_index(does_not_contain_option_condition, "index_contacts_applied_tags_on_contact_id")
      expected_sql = <<~SQL.squish
        SELECT
          `contacts`.*
        FROM
          `contacts`
        WHERE (`contacts`.`id` NOT IN (SELECT
                `contacts_applied_tags`.`contact_id` FROM `contacts_applied_tags`
                FORCE INDEX(`index_contacts_applied_tags_on_contact_id`)
              WHERE (`contacts_applied_tags`.`tag_id` IN (1))))

      SQL
      assert_equal convert(expected_sql), query.get_query.to_sql
    end

    def does_not_contain_option_condition
      Refine::Blueprints::Blueprint.new
        .criterion("tags.id",
          clause: OptionCondition::CLAUSE_NOT_IN,
          selected: ["1"])
    end

    def create_filter(blueprint)
      # Contacts Filter
      BlankTestFilter.new(blueprint,
        Contact.all,
        [
          OptionCondition.new("tags.id").with_options([{id: "1", display: "Option 1"}])
        ],
        Contact.arel_table)
    end

    def create_filter_with_through_id(blueprint)
      # Contacts Filter
      BlankTestFilter.new(blueprint,
        Contact.all,
        [
          OptionCondition.new("tags.id").with_options([{id: "1", display: "Option 1"}]).with_through_id_relationship
        ],
        Contact.arel_table)
    end

    def create_filter_with_through_id_forced_index(blueprint, index)
      # Contacts Filter
      BlankTestFilter.new(blueprint,
        Contact.all,
        [
          OptionCondition.new("tags.id").with_options([{id: "1", display: "Option 1"}]).with_through_id_relationship.with_forced_index(index)
        ],
        Contact.arel_table)
    end
  end

  class Contact < ActiveRecord::Base
    has_many :applied_tags, class_name: "Refine::Conditions::Contact::AppliedTag", dependent: :destroy
    has_many :tags, through: :applied_tags
  end

  class Contact::AppliedTag < ActiveRecord::Base
    belongs_to :contact, touch: true
    belongs_to :tag, class_name: "Refine::Conditions::Contact::Tag"
    self.table_name = "contacts_applied_tags"
  end

  class Contact::Tag < ActiveRecord::Base
    has_many :applied_tags, class_name: "Refine::Conditions::Contact::AppliedTag", dependent: :destroy
    has_many :contacts, through: :applied_tags
    self.table_name = "contacts_tags"
  end
end
