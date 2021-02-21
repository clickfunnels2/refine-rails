import { Controller } from "stimulus";

export default class extends Controller {
  static targets = [ "blueprint" ]

  static values = { groupId: Number, blueprintPath: Array };

  connect() {
    const refineElement = document.getElementById('refine');
    this.stateController = this.application.getControllerForElementAndIdentifier(
      refineElement,
      'refine--state',
    );
  }

  criterion(event) {
    event.preventDefault();
    event.stopPropagation();
    const { blueprint, conditions } = this.stateController;
    const condition = conditions[0];
    const group = blueprint[this.groupIdValue];
    const { meta } = condition;

    const criterion = {
      depth: 1,
      type: "criterion",
      condition_id: condition.id,
      input: { clause: meta.clauses[0] },
    };

    const criterionLocals = {
      group_id: this.groupIdValue,
      criterion_id: `${this.groupIdValue}_${group.length}`,
      criterion,
      conditions,
      blueprint_path: this.blueprintPathValue.concat(group.length),
    };

    this.blueprintTarget.value = JSON.stringify(criterionLocals);
    this.stateController.addCriterion(this.groupIdValue, criterion);
    this.element.requestSubmit();
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
