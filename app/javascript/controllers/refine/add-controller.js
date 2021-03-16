import { Controller } from "stimulus";

export default class extends Controller {
  static targets = [ "blueprint" ];
  static values = {
    previousCriterionId: Number,
  };

  connect() {
    const refineElement = document.getElementById('refine');
    this.state = this.application.getControllerForElementAndIdentifier(
      refineElement,
      'refine--state',
    );
  }

  criterion() {
    this.state.addCriterion(this.previousCriterionIdValue);
    this.updateBlueprintInput();
  }

  group() {
    this.state.addGroup();
    this.updateBlueprintInput();
  }

  updateBlueprintInput() {
    this.blueprintTarget.value = JSON.stringify(this.state.blueprint);
  }
};
