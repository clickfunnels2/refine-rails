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
    stateController.update(pathValue, event.target.value, (url) => {
      const frame = document.getElementById(frameIdValue);
      frame.src = url;
    });
  }
}
