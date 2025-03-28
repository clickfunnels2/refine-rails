require "test_helper"
require "support/refine/test_double_filter"
require "support/refine/contact_complex_relationships"
require "refine/invalid_filter_error"

describe Refine::Filter do
  include FilterTestHelper

  around do |test|
    ApplicationRecord.connection.execute("CREATE TABLE contacts (id bigint primary key);")
    ApplicationRecord.connection.execute("CREATE TABLE forms_submissions (id bigint primary key, contact_id bigint);")
    ApplicationRecord.connection.execute("CREATE TABLE forms_submissions_answers (id bigint primary key, submission_id bigint, field_id bigint, fields_option_id bigint);")
    ApplicationRecord.connection.execute("CREATE TABLE forms_submissions_answers_selected_options (id bigint primary key, answer_id bigint, fields_option_id bigint);")
    ApplicationRecord.connection.execute("CREATE TABLE forms_fields (id bigint primary key);")
    ApplicationRecord.connection.execute("CREATE TABLE forms_answers (id bigint primary key);")
    ApplicationRecord.connection.execute("CREATE TABLE contacts_applied_tags (id bigint primary key, contact_id bigint, tag_id bigint);")
    ApplicationRecord.connection.execute("CREATE TABLE contacts_tags (id bigint primary key);")
    test.call
    ApplicationRecord.connection.execute("DROP TABLE contacts, forms_submissions, forms_submissions_answers, forms_submissions_answers_selected_options, forms_fields, forms_answers, contacts_applied_tags, contacts_tags;")
  end

  describe "get_flat_query" do
    it "referencing an attribute on a related table thats not the primary key generates a proper query" do
      initial_query = Contact.all
      filter = create_filter(text_custom_field_criteria)

      expected_sql = <<-SQL.squish
        SELECT DISTINCT `contacts`.* FROM `contacts`
          INNER JOIN `forms_submissions` ON `forms_submissions`.`id` = `contacts`.`custom_attributes_id`
          INNER JOIN `forms_submissions_answers` ON `forms_submissions_answers`.`submission_id` = `forms_submissions`.`id`
          WHERE ((`forms_submissions_answers`.`entry` = 'test'))
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql
    end

    it "single-select custom attributes generate the proper query" do
      initial_query = Contact.all
      filter = create_filter(option_custom_field_criteria)

      expected_sql = <<-SQL.squish
        SELECT DISTINCT `contacts`.* FROM `contacts` 
          INNER JOIN `forms_submissions` ON `forms_submissions`.`id` = `contacts`.`custom_attributes_id` 
          INNER JOIN `forms_submissions_answers` ON `forms_submissions_answers`.`submission_id` = `forms_submissions`.`id` 
          WHERE ((`forms_submissions_answers`.`fields_option_id` IN (2, 3)))
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql
    end

    it "multi-select custom attributes generate the proper query" do
      initial_query = Contact.all
      filter = create_filter(option_multi_custom_field_criteria)

      expected_sql = <<-SQL.squish
        SELECT DISTINCT `contacts`.* FROM `contacts` 
          INNER JOIN `forms_submissions` ON `forms_submissions`.`id` = `contacts`.`custom_attributes_id`
          INNER JOIN `forms_submissions_answers` ON `forms_submissions_answers`.`submission_id` = `forms_submissions`.`id`
          INNER JOIN `forms_submissions_answers_selected_options` ON `forms_submissions_answers_selected_options`.`answer_id` = `forms_submissions_answers`.`id`
          WHERE ((`forms_submissions_answers_selected_options`.`fields_option_id` IN (1, 2)))
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql
    end

    it "combining different custom attributes and tags generate the proper query" do
      initial_query = Contact.all
      filter = create_filter(multiple_conditions_criteria)

      expected_sql = <<-SQL.squish
        SELECT DISTINCT `contacts`.* FROM `contacts`
          INNER JOIN `forms_submissions` ON `forms_submissions`.`id` = `contacts`.`custom_attributes_id`
          INNER JOIN `forms_submissions_answers` ON `forms_submissions_answers`.`submission_id` = `forms_submissions`.`id`
          INNER JOIN `contacts_applied_tags` ON `contacts_applied_tags`.`contact_id` = `contacts`.`id`
          WHERE ((`forms_submissions_answers`.`fields_option_id` IN (2, 3))) AND ((`contacts_applied_tags`.`tag_id` IN (1, 2)))
      SQL
      assert_equal expected_sql, filter.get_flat_query.to_sql
    end
  end

  def create_filter(blueprint=nil)
    field_options = [{id: "1", display: "field1"}, {id: "2", display: "field2"}, {id: "3", display: "field3"}, {id: "4", display: "field4"}]
    selected_options = [{id: "1", display: "selected1"}, {id: "2", display: "selected2"}, {id: "3", display: "selected3"}, {id: "4", display: "selected4"}]
    BlankTestFilter.new(blueprint,
      Contact.all,
      [
        Refine::Conditions::TextCondition.new("custom_attributes.answers.entry"),
        Refine::Conditions::OptionCondition.new("custom_attributes.answers.selected_options.fields_option_id").with_options(proc { field_options }),
        Refine::Conditions::OptionCondition.new("custom_attributes.answers.fields_option_id").with_options(proc { selected_options }),
        Refine::Conditions::OptionCondition.new("tags.id").with_options(proc { field_options }),
      ],
      Contact.arel_table)
  end

  def text_custom_field_criteria
    [{
      depth: 0,
      type: "criterion",
      condition_id: "custom_attributes.answers.entry",
      input: {
        clause: "eq",
        value: "test"
      }
    }]
  end

  def option_custom_field_criteria
    [{
      depth: 0,
      type: "criterion",
      condition_id: "custom_attributes.answers.fields_option_id",
      input: {
        clause: "in",
        selected: ["2", "3"]
      }
    }]
  end

  def option_multi_custom_field_criteria
    [{
      depth: 0,
      type: "criterion",
      condition_id: "custom_attributes.answers.selected_options.fields_option_id",
      input: {
        clause: "in",
        selected: ["1", "2"]
      }
    }]
  end

  def multiple_conditions_criteria
    [{
      depth: 0,
      type: "criterion",
      condition_id: "custom_attributes.answers.fields_option_id",
      input: {
        clause: "in",
        selected: ["2", "3"]
      }
    }, { # conjunction
      depth: 0,
      type: "conjunction",
      word: "and"
    }, {
      depth: 0,
      type: "criterion",
      condition_id: "tags.id",
      input: {
        clause: "in",
        selected: ["1", "2"]
      } 
    }]
  end

end
