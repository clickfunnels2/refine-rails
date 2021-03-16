import { Controller } from "stimulus";

export default class extends Controller {
  static targets = [ 'blueprint' ];
  static values = {
    criterionId: Number,
  }

  connect() {
    const refineElement = document.getElementById('refine');
    this.state = this.application.getControllerForElementAndIdentifier(
      refineElement,
      'refine--state',
    );
  }

  criterion() {
    const { state, criterionIdValue } = this;
    state.deleteCriterion(criterionIdValue);
    this.blueprintTarget.value = JSON.stringify(this.state.blueprint);
  }
}
