import FormController from './form-controller';

export default class extends FormController {
  static targets = [ "blueprint" ];
  static values = {
    previousCriterionId: Number,
  };

  criterion() {
    this.state.addCriterion(this.previousCriterionIdValue);
    this.updateBlueprintInput();
  }

  group() {
    this.state.addGroup();
    this.updateBlueprintInput();
  }
};
