require "test_helper"

class Hammerstone::Refine::Filters::BlueprintEditorTest < ActiveSupport::TestCase

  def test_add_single_criterion
    blueprint = []
    editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
    editor.add(criterion: {
      condition_id: "id",
      input: {
        clause: "eq",
        value: "foo"
      }
    })

    expected = [
      {
        depth: 1,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value: "foo"
        }
      }
    ]

    assert_equal expected, blueprint
  end

  def test_add_criteria_with_and
    blueprint = []
    editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
    editor.add(criterion: {
      condition_id: "id",
      input: {
        clause: "eq",
        value: "fun"
      }
    })

    editor.add(criterion: {
      condition_id: "id",
      input: {
        clause: "eq",
        value: "inthesun"
      }
    })

    expected = [
      {
        depth: 1,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value: "fun"
        }
      },
      { # conjunction
        depth: 1,
        type: "conjunction",
        word: "and"
      },
      { # criterion
        depth: 1,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value: "inthesun"
        }
      }
    ]

    assert_equal expected, blueprint
  end

  def test_add_criteria_with_ors
    blueprint = []
    editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
    editor.add(criterion: {
      condition_id: "id",
      input: {
        clause: "eq",
        value: "dogs"
      }
    })

    editor.add(conjunction: "or", criterion: {
      condition_id: "id",
      input: {
        clause: "eq",
        value: "cats"
      }
    })

    expected = [
      {
        depth: 1,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value: "dogs"
        }
      },
      { # conjunction
        depth: 0,
        type: "conjunction",
        word: "or"
      },
      { # criterion
        depth: 1,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value: "cats"
        }
      }
    ]

    assert_equal expected, blueprint
  end

  def test_add_criteria_with_ands_and_ors
    blueprint = []
    editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
    editor.add(criterion: {
      condition_id: "id",
      input: {
        clause: "eq",
        value: "one"
      }
    })

    editor.add(conjunction: "or", criterion: {
      condition_id: "id",
      input: {
        clause: "eq",
        value: "two"
      }
    })

    editor.add(criterion: {
      condition_id: "id",
      input: {
        clause: "eq",
        value: "three"
      }
    })

    expected = [
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "one",
        },
      },
      {
        type: "conjunction",
        word: "or",
        depth: 0,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "two"
        }
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "three"
        }
      }
    ]

    assert_equal expected, blueprint
  end

  def test_update_criterion
    blueprint = [
     {
       depth: 1,
       type: "criterion",
       condition_id: "id",
       input: {
         clause: "eq",
         value: "fun"
       }
     },
     { # conjunction
       depth: 1,
       type: "conjunction",
       word: "and"
     },
     { # criterion
       depth: 1,
       type: "criterion",
       condition_id: "id",
       input: {
         clause: "eq",
         value: "inthesun"
       }
     }
   ]

   editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
   editor.update(2, criterion: {
     condition_id: "id",
     input: {
       clause: "eq",
       value: "funagain"
     }
   })

   expected = [
     {
       depth: 1,
       type: "criterion",
       condition_id: "id",
       input: {
         clause: "eq",
         value: "fun"
       }
     },
     { # conjunction
       depth: 1,
       type: "conjunction",
       word: "and"
     },
     { # criterion
       depth: 1,
       type: "criterion",
       condition_id: "id",
       input: {
         clause: "eq",
         value: "funagain"
       }
     }
   ]

   assert_equal expected, blueprint
  end

  def test_delete_criterion_basic
    blueprint = [
      {
        depth: 1,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value: "foo"
        }
      }
    ]
    editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)

    editor.delete(0)
    assert_equal [], blueprint
  end

  def test_delete_criterion_at_beginning_of_group
    # deleteing a criterion that appears at the first position in a group should remove
    # the AND conjunction AFTER it
    

    blueprint = [
      {
        depth: 1,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value: "fun"
        }
      },
      { # conjunction
        depth: 1,
        type: "conjunction",
        word: "and"
      },
      { # criterion
        depth: 1,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value: "inthesun"
        }
      }
    ]

    editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
    editor.delete(0)

    expected = [
      { # criterion
        depth: 1,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value: "inthesun"
        }
      }
    ]

    assert_equal expected, blueprint
  end

  def test_delete_criterion_after_beginning_of_group
    # deleteing a criterion that appears after the first position in a group should remove
    # the AND conjunction BEFORE it
    
    blueprint = [
      {
        depth: 1,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value: "fun"
        }
      },
      { # conjunction
        depth: 1,
        type: "conjunction",
        word: "and"
      },
      { # criterion
        depth: 1,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value: "inthesun"
        }
      }
    ]

      editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
      editor.delete(2)

      expected = [
        {
          depth: 1,
          type: "criterion",
          condition_id: "id",
          input: {
            clause: "eq",
            value: "fun"
          }
        }
      ]

    assert_equal expected, blueprint
  end

  def test_delete_criterion_when_deleting_entire_first_group
    blueprint = [
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "one",
        },
      },
      {
        type: "conjunction",
        word: "or",
        depth: 0,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "two"
        }
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "three"
        }
      }
    ]

    editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
    editor.delete(0)

    expected = [
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "two"
        }
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "three"
        }
      }
    ]

    assert_equal expected, blueprint
  end

  def test_delete_criterion_when_deleting_part_of_first_group
    blueprint = [
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "one",
        },
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "one and a half",
        },
      },
      {
        type: "conjunction",
        word: "or",
        depth: 0,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "two"
        }
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "three"
        }
      }
    ]

    editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
    editor.delete(2)

    expected = [
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "one",
        },
      },
      {
        type: "conjunction",
        word: "or",
        depth: 0,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "two"
        }
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "three"
        }
      }
    ]

    assert_equal expected, blueprint
  end

  def test_delete_criterion_when_deleting_entire_last_group
    blueprint = [
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "one",
        },
      },
      {
        type: "conjunction",
        word: "or",
        depth: 0,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "two"
        }
      }
    ]

    editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
    editor.delete(2)

    expected = [
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "one"
        }
      }
    ]

    assert_equal expected, blueprint
  end

  def test_delete_criterion_when_deleting_part_of_last_group
    blueprint = [
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "one",
        },
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "one and a half",
        },
      },
      {
        type: "conjunction",
        word: "or",
        depth: 0,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "two"
        }
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "three"
        }
      }
    ]

    editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
    editor.delete(4)

    expected = [
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "one",
        },
      },
      {
        type: "conjunction",
        word: "and",
        depth: 1,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "one and a half",
        },
      },
      {
        type: "conjunction",
        word: "or",
        depth: 0,
      },
      {
        type: "criterion",
        condition_id: "id",
        depth: 1,
        input: {
          clause: "eq",
          value: "three"
        }
      }
    ]

    assert_equal expected, blueprint
  end
end
