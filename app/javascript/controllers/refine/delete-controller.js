import ServerRefreshController from './server-refresh-controller';

export default class extends ServerRefreshController {
  static values = {
    criterionId: Number,
  }

  criterion() {
    const { state, criterionIdValue } = this;
    state.deleteCriterion(criterionIdValue);
    this.refreshFromServer()
  }
}
