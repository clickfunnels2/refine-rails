require "test_helper"
require "support/hammerstone/filter_test_helper"

module Hammerstone::Refine::Conditions
  describe TextCondition do
    include FilterTestHelper

    let(:condition_under_test) { TextCondition.new("text_test") }

    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (text_test varchar(256));")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    it "correctly executes clause equals" do
      data = {clause: TextCondition::CLAUSE_EQUALS, value: "foo"}
      expected_sql = <<~SQL.squish
        SELECT "t".* FROM "t" WHERE ("t"."text_test" = 'foo')
      SQL
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    it "correctly executes clause doesnt equals" do
      data = {clause: TextCondition::CLAUSE_DOESNT_EQUAL, value: "foo"}
      expected_sql = "SELECT \"t\".* FROM \"t\" WHERE (\"t\".\"text_test\" != 'foo' OR \"t\".\"text_test\" IS NULL)"
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    it "correctly executes clause starts with" do
      data = {clause: TextCondition::CLAUSE_STARTS_WITH, value: "foo"}
      expected_sql = "SELECT \"t\".* FROM \"t\" WHERE (\"t\".\"text_test\" LIKE 'foo%')"
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    it "correctly executes clause ends with" do
      data = {clause: TextCondition::CLAUSE_ENDS_WITH, value: "foo"}
      expected_sql = "SELECT \"t\".* FROM \"t\" WHERE (\"t\".\"text_test\" LIKE '%foo')"
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    it "correctly executes clause contains" do
      data = {clause: TextCondition::CLAUSE_CONTAINS, value: "foo"}
      expected_sql = "SELECT \"t\".* FROM \"t\" WHERE (\"t\".\"text_test\" LIKE '%foo%')"
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    it "correctly executes clause doesn't contains" do
      data = {clause: TextCondition::CLAUSE_DOESNT_CONTAIN, value: "foo"}
      expected_sql = "SELECT \"t\".* FROM \"t\" WHERE (\"t\".\"text_test\" NOT LIKE '%foo%' OR \"t\".\"text_test\" IS NULL)"
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    it "correctly executes clause set" do
      data = {clause: TextCondition::CLAUSE_SET}
      expected_sql = "SELECT \"t\".* FROM \"t\" WHERE (\"t\".\"text_test\" IS NOT NULL OR \"t\".\"text_test\" != '')"
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    it "correctly executes clause not set" do
      data = {clause: TextCondition::CLAUSE_NOT_SET}
      expected_sql = "SELECT \"t\".* FROM \"t\" WHERE (\"t\".\"text_test\" IS NULL OR \"t\".\"text_test\" = '')"
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    it "correctly executes clause not set" do
      data = {clause: TextCondition::CLAUSE_NOT_SET}
      expected_sql = "SELECT \"t\".* FROM \"t\" WHERE (\"t\".\"text_test\" IS NULL OR \"t\".\"text_test\" = '')"
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    it "correctly executes clause doesn't start with" do
      data = {clause: TextCondition::CLAUSE_DOESNT_START_WITH, value: "foo"}
      expected_sql = "SELECT \"t\".* FROM \"t\" WHERE (\"t\".\"text_test\" NOT LIKE 'foo%')"
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end

    it "correctly executes clause doesn't end with" do
      data = {clause: TextCondition::CLAUSE_DOESNT_END_WITH, value: "foo"}
      expected_sql = "SELECT \"t\".* FROM \"t\" WHERE (\"t\".\"text_test\" NOT LIKE '%foo')"
      assert_equal convert(expected_sql), apply_condition_on_test_filter(condition_under_test, data).to_sql
    end
  end
end
