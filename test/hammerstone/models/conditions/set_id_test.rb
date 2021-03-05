require "test_helper"

module Hammerstone::Refine::Conditions
  describe "Sets Id" do


    around do |test|
      ApplicationRecord.connection.execute("CREATE TABLE t (test_bool boolean);")
      test.call
      ApplicationRecord.connection.execute("DROP TABLE t;")
    end

    # it 'sets id' do
    #   condition = BooleanCondition.new('boolean_test')
    #   assert_equal condition.id, 'boolean_test'
    # end
  end
end
