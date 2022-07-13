import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    criterionId: Number,
    input: Object,
  };

  connect() {
    const refineElement = document.getElementById('refine');
    this.state = this.application.getControllerForElementAndIdentifier(
      refineElement,
      'refine--state',
    );

    this.state.updateInput(
      this.criterionIdValue,
      this.inputValue,
    );
  }
}
