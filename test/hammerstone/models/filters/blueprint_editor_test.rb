require "test_helper"

class Hammerstone::Refine::Filters::BlueprintEditorTest < MiniTest::Test

  def test_single_basic_condition
    skip "WIP"
    blueprint = []
    editor = Hammerstone::Refine::Filters::BlueprintEditor.new(blueprint)
    editor.append(
      condition_id: "id",
      input: {
        clause: "eq",
        value: "foo"
      }
    )

    expected = [
      {
        depth: 0,
        type: "criterion",
        condition_id: "id",
        input: {
          clause: "eq",
          value1: "foo"
        }
      }
    ]

    assert_equal expected, blueprint
  end

end