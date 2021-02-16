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
