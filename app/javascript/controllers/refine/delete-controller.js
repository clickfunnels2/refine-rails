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
    const { stateController, criterionId } = this;
    stateController.delete(criterionId);
  }
}
