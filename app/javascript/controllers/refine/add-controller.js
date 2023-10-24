import ServerRefreshController from './server-refresh-controller'
import { FetchRequest } from '@rails/request.js'

export default class extends ServerRefreshController {
  static values = {
    previousCriterionId: Number,
  }

  async criterion() {
    const isValid = await this.validateBlueprint()
    if (isValid) {
      this.state.addCriterion(this.previousCriterionIdValue)
    }
    this.refreshFromServer({includeErrors: !isValid})
  }

  async group() {
    const isValid = await this.validateBlueprint()
    if (isValid) {
      this.state.addGroup()
    }
    this.refreshFromServer({includeErrors: !isValid})
  }

  async validateBlueprint(blueprint) {
    const { state } = this

    const request = new FetchRequest(
      "GET",
      this.state.validateBlueprintUrlValue,
      {
        query: {
          "refine_filters_builder[filter_class]": this.state.filterName,
          "refine_filters_builder[blueprint_json]": JSON.stringify(this.state.blueprint),
          "refine_filters_builder[client_id]": this.state.clientIdValue
        }
      }
    )
    const response = await request.perform()
    return response.ok
  }
}
