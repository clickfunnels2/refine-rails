# require "test_helper"
# require "support/refine/cf2_test_contacts_filter"

# module Refine::Conditions

#   describe "Contacts Filter nested inline filters" do

#     before do
#       load_seeds
#       5.times { create(:course, site: @site, title: "Learn") }
#       # Create a saved courses filter for this test (currently created in UI on Courses page)
#       state = {"type"=>"CoursesFilter", "blueprint"=>[{"depth"=>1, "type"=>"criterion", "condition_id"=>"title", "input"=>{"clause"=>"eq", "value"=>"Learn"}, "position"=>0}]}.to_json.to_s
#       Refine::StoredFilter.destroy_all
#       Refine::StoredFilter.create(name: 'learn_courses', state: state, id: 1)
#     end

#     # All contacts that have viewed (event type id = 1) a course with the title learn using the stored filter
#     it 'works on events table in the same database' do
#       query = Cf2TestContactsFilter.new(events_table_example, Contact.where(workspace_id: 2))
#       expected_sql = <<~SQL.squish
#       SELECT
#         `contacts`.*
#       FROM
#         `contacts`
#       WHERE
#         `contacts`.`workspace_id` = 2
#         AND (`contacts`.`id` IN (SELECT
#           `events`.`contact_id` FROM `events`
#           WHERE (`events`.`type_id` = 1)
#           AND `events`.`course_id` IN (SELECT
#                 `courses`.`id` FROM `courses`
#                 WHERE (`courses`.`title` = 'Learn'))))
#       SQL
#       assert_equal convert(expected_sql), query.get_query.to_sql
#     end

#     it 'works when filter id comes in via the blueprint' do
#       query = Cf2TestContactsFilter.new(events_table_example, Contact.where(workspace_id: 2))
#       expected_sql = <<~SQL.squish
#       SELECT
#         `contacts`.*
#       FROM
#         `contacts`
#       WHERE
#         `contacts`.`workspace_id` = 2
#         AND (`contacts`.`id` IN (SELECT
#           `events`.`contact_id` FROM `events`
#           WHERE (`events`.`type_id` = 1)
#           AND `events`.`course_id` IN (SELECT
#                 `courses`.`id` FROM `courses`
#                 WHERE (`courses`.`title` = 'Learn'))))
#       SQL
#       assert_equal convert(expected_sql), query.get_query.to_sql
#     end

#     it 'works on events table rolling up courses into ids' do
#       ENV['MULTIPLE_DB_1'] = "true"
#       # This array returns the results of SELECT `courses`.`id` FROM `courses` WHERE (`courses`.`title` = 'Learn')
#       array_of_ids = Course.where(title: "Learn").pluck(:id).join(", ")

#       query = Cf2TestContactsFilter.new(events_table_example, Contact.where(workspace_id: 2))
#       expected_sql = <<~SQL.squish
#         SELECT
#           `contacts`.*
#         FROM
#           `contacts`
#         WHERE
#           `contacts`.`workspace_id` = 2
#           AND (`contacts`.`id` IN (SELECT
#                 `events`.`contact_id` FROM `events`
#               WHERE (`events`.`type_id` = 1)
#               AND `events`.`course_id` IN (#{array_of_ids})))
#         SQL
#       assert_equal convert(expected_sql), query.get_query.to_sql
#       ENV['MULTIPLE_DB_1'] = nil
#     end

#     # it 'works on events table rolling up courses into ids and rolling events.course_id up to ids' do
#     # TODO: Create this test after creating quality sample data
#     #   ENV['MULTIPLE_DB_1'] = "true"
#     #   ENV['MULTIPLE_DB_2'] = "true"
#     #   query = Cf2TestContactsFilter.new(events_table_example, Contact.where(workspace_id: 2))

#     #   expected_sql = <<~SQL.squish
#     #     SELECT
#     #       `contacts`.*
#     #     FROM
#     #       `contacts`
#     #     WHERE
#     #       `contacts`.`workspace_id` = 2
#     #       AND (`contacts`.`id` IN (1,2))

#     #     SQL
#     #   assert_equal convert(expected_sql), query.get_query.to_sql
#     # end

#     def events_table_example
#       # TODO rename
#        [{:depth=>0, :index=>0, :type=>"criterion", :condition_id=>"Has", :input=>{:clause=>"eq", :selected=>["1"], :saved_filters=>{:id=>"1"}}}]
#     end
#   end
# end
