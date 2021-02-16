import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    frameId: String,
    path: Array,
  }

  condition(event) {
    const refineElement = document.getElementById('refine');
    const blueprintController = this.application.getControllerForElementAndIdentifier(
      refineElement,
      'refine--state',
    );
    const { frameIdValue } = this;
    blueprintController.updateBlueprint(this.pathValue, event.target.value, (url) => {
      const frame = document.getElementById(frameIdValue);
      frame.src = url;
    });
    console.log(blueprintController.configurationValue);
  }
}
