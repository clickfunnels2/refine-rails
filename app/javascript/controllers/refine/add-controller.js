import ServerRefreshController from './server-refresh-controller'

export default class extends ServerRefreshController {
  static values = {
    previousCriterionId: Number,
  }

  criterion() {
    this.state.addCriterion(this.previousCriterionIdValue)
    this.refreshFromServer()
  }

  group() {
    this.state.addGroup()
    this.refreshFromServer()
  }
}
