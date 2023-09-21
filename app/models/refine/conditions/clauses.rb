module Refine::Conditions
  class Clauses
    EQUALS = "eq"
    DOESNT_EQUAL = "dne"

    SET = "st"
    NOT_SET = "nst"

    TRUE = "true"
    FALSE = "false"

    LESS_THAN_OR_EQUAL = "lte"
    LESS_THAN = "lt"
    BETWEEN = "btwn"
    NOT_BETWEEN = "nbtwn"
    GREATER_THAN = "gt"
    GREATER_THAN_OR_EQUAL = "gte"

    EXACTLY = "exct"

    EXISTS = "exst"
    DOESNT_EXIST = "dexst"

    IN = "in"
    NOT_IN = "nin"

    CONTAINS = "cont"
    DOESNT_CONTAIN = "dcont"

    STARTS_WITH = "sw"
    ENDS_WITH = "ew"

    DOESNT_START_WITH = "dsw"
    DOESNT_END_WITH = "dew"

    FLIPPABLE = [NOT_IN, DOESNT_EQUAL].freeze
  end
end
