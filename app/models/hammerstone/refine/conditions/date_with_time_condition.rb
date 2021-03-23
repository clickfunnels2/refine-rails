module Hammerstone::Refine::Conditions
  class DateWithTimeCondition < DateCondition
    def boot
      @attribute_type = ATTRIBUTE_TYPE_DATE_WITH_TIME
      super
    end
  end
end