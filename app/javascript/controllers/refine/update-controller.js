import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    frameId: String,
    path: Array,
  }

  connect() {
    const refineElement = document.getElementById('refine');
    this.stateController = this.application.getControllerForElementAndIdentifier(
      refineElement,
      'refine--state',
    );
  }

  select(event) {
    const { stateController, pathValue } = this;
    const selectElement = event.target;
    const selected = [];

    // do this instead of selectedOptions to support IE
    for (var i = 0; i < selectElement.length; i++) {
        if (selectElement.options[i].selected) selected.push(selectElement.options[i].value);
    }
    stateController.update(
      pathValue.concat('input', 'selected'),
      selected,
    );
  }

  clause(event) {
    const { frameIdValue, stateController, pathValue } = this;
    const frame = document.getElementById(frameIdValue);

    stateController.update(
      pathValue.concat('input', 'clause'),
      event.target.value,
      url => frame.src = url,
    );
  }

  condition(event) {
    const { frameIdValue, stateController, pathValue } = this;
    const element = event.target;
    const newConditionId = element.value;
    const { conditionId } = element.dataset;
    const config = this.stateController.conditionConfigFor(newConditionId);

    // set selected clause to the first clause by default
    const newInput = {
      clause: config.meta.clauses[0].id,
    };

    stateController.update(
      pathValue.concat('condition_id'),
      newConditionId,
    );

    stateController.update(
      pathValue.concat('input'),
      newInput,
      (url) => {
        const frame = document.getElementById(frameIdValue);
        frame.src = url;
      },
    );
  }
}
