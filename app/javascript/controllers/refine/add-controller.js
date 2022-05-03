import FormController from './form-controller'

export default class extends FormController {
  static values = {
    previousCriterionId: Number,
    method: String,
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
