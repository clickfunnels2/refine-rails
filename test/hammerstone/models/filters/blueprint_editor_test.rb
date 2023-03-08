require "test_helper"

class Hammerstone::Refine::Filters::BlueprintEditorTest < ActiveSupport::TestCase

  def test_single_basic_condition
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

  def test_basic_filter_with_ands
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

  def test_basic_filter_with_ors
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

  def test_basic_filter_with_groups
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

end
