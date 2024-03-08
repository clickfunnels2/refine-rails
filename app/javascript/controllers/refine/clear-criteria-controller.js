import ServerRefreshController from './server-refresh-controller';

export default class extends ServerRefreshController {
  clear() {
    console.log("Clearing criteria")
    const { state } = this;
    state.clearCriteria();
    this.refreshFromServer()
  }
}
