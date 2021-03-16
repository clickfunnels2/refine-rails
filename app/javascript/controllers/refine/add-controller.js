import { Controller } from "stimulus";

const createCriterion = (id, depth, meta) => {
  return {
    depth,
    type: "criterion",
    condition_id: id,
    input: { clause: meta.clauses[0].id },
  };
};

export default class extends Controller {
  static targets = [ "blueprint" ];

  connect() {
    const refineElement = document.getElementById('refine');
    this.state = this.application.getControllerForElementAndIdentifier(
      refineElement,
      'refine--state',
    );
  }

  criterion(event) {
    event.preventDefault();
    event.stopPropagation();
    const { blueprint, conditions } = this.state;
    const condition = conditions[0];
    const group = blueprint[this.groupIdValue];
    const { meta } = condition;

    const criterion = createCriterion(condition.id, 1, meta);

    const criterionLocals = {
      group_id: this.groupIdValue,
      criterion_id: `${this.groupIdValue}_${group.length}`,
      criterion,
      conditions,
      blueprint_path: this.blueprintPathValue.concat(group.length),
    };

    this.blueprintTarget.value = JSON.stringify(criterionLocals);
    this.state.addCriterion(this.groupIdValue, criterion);
    this.element.requestSubmit();
  }

  group(event) {
    this.state.addGroup();

    event.preventDefault();
    event.stopPropagation();

    this.submitForm();
  }

  submitForm() {
    this.blueprintTarget.value = JSON.stringify(this.state.blueprint);
    this.element.requestSubmit();
  }

  condition() {
  }
};
