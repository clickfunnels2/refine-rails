import { Controller } from "stimulus";

export default class extends Controller {
  static targets = [ "blueprint" ]

  connect() {
    const refineElement = document.getElementById('refine');
    this.stateController = this.application.getControllerForElementAndIdentifier(
      refineElement,
      'refine--state',
    );
  }

  group(event) {
    event.preventDefault();
    event.stopPropagation();
    const { blueprint, conditions } = this.stateController;
    const groupId = blueprint.length;
    const condition = conditions[0];
    const { meta } = condition;

    const group = [{
      condition_id: condition.id,
      input: { clause: meta.clauses[0] },
    }]

    const groupLocals = {
      group_id: groupId,
      criteria: group,
      conditions,
      blueprint_path: ['blueprint', groupId],
    };

    this.stateController.addGroup(group);
    this.blueprintTarget.value = JSON.stringify(groupLocals);
    this.element.requestSubmit();
  }

  condition() {
  }
};
