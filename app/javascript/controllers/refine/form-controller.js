import { Controller } from "stimulus";
import { delegate } from 'jquery-events-to-dom-events';

export default class extends Controller {
  connect() {
    const refineElement = document.getElementById('refine');

    // for select2 jquery events and datepicker
    delegate('change');

    this.state = this.application.getControllerForElementAndIdentifier(
      refineElement,
      'refine--state',
    );
    this.blueprintInput = this.addHiddenInput('blueprint');
    this.addHiddenInput('filter', this.state.filterName);
    this.finishUpdate();
  }

  addHiddenInput(name, initialValue) {
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = name;
    input.value = initialValue || '';
    this.element.appendChild(input);
    return input;
  }

  // called on connect
  finishUpdate() {
    this.state.finishUpdate();
  }

  // Call this on submit
  startUpdate() {
    this.blueprintInput.value = JSON.stringify(this.state.blueprint);
    this.state.startUpdate();
  }

  submitForm() {
    this.startUpdate();
    this.element.requestSubmit();
  }
}
