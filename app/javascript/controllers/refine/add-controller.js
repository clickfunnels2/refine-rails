import FormController from './form-controller'

export default class extends FormController {
  static values = {
    previousCriterionId: Number,
  }

  criterion() {
    this.state.addCriterion(this.previousCriterionIdValue)
    this.startUpdate()
  }

  group() {
    this.state.addGroup()
    this.startUpdate()
  }
}
