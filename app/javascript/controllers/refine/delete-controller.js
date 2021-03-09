import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    domId: String,
    path: Array,
  }

  connect() {
    const refineElement = document.getElementById('refine');
    this.stateController = this.application.getControllerForElementAndIdentifier(
      refineElement,
      'refine--state',
    );
  }

  criterion(event) {
    const { stateController, pathValue, domIdValue } = this;
    const element = document.getElementById(domIdValue);
    stateController.delete(pathValue);
    element.parentNode.removeChild(element);
  }
}
