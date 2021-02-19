import { Controller } from "stimulus";

export default class extends Controller {

  connect() {
    const refineElement = document.getElementById('refine');
    this.stateController = this.application.getControllerForElementAndIdentifier(
      refineElement,
      'refine--state',
    );
  }

  group(event) {
    console.log('add group');
    event.preventDefault();
    event.stopImmediatePropagation();
  }

  condition() {
  }
};
