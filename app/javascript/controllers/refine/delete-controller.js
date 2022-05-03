import FormController from './form-controller';

export default class extends FormController {
  static values = {
    criterionId: Number,
    method: String
  }

  criterion() {
    const { state, criterionIdValue } = this;
    state.deleteCriterion(criterionIdValue);
    this.startUpdate();
  }
}
