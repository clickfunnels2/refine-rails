import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    criterionId: Number,
    input: Object,
  };

  connect() {
    this.state = this.getStateController()

    this.state.updateInput(
      this.criterionIdValue,
      this.inputValue,
    );
  }

  getStateController() {
    let currentElement = this.element

    while(currentElement !== document.body) {
      const controller = this.application.getControllerForElementAndIdentifier(currentElement, 'refine--state')
      if (controller) {
        return controller
      } else {
        currentElement = currentElement.parentNode
      }
    }

    return null
  }
}
