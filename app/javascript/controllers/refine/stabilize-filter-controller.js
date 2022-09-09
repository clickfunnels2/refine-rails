import { Controller } from "@hotwired/stimulus"
import { filterUnstableEvent, filterStabilizedEvent, filterInvalidEvent } from '../../refine/helpers'


// This controller is responsible for maintaining the stableId and updating
// it from the server
export default class extends Controller {
  static values = {
    stableId: String,
    updateStableIdUrl: String,
    filterName: String
  }

  static targets = []

  connect() {
    this.element.stabilizeFilterController = this
    this.stableIdValue = new URLSearchParams(window.location.search).get("stable_id")
  }

  async updateStableId(event) {
    filterUnstableEvent(this.blueprint)
    const blueprint = event.detail.blueprint
    const validationResult = await this.validateBlueprint(blueprint)
    if (validationResult.stableId) {
      this.stableIdValue = validationResult.stableId
      filterStabilizedEvent(this.element, this.stableIdValue, this.filterNameValue)
      filterStabilizedEvent(window, this.stableIdValue, this.filterNameValue)
    } else {
      const { errors } = validationResult
      filterInvalidEvent({blueprint, errors})
    }
  }

  async validateBlueprint(blueprint) {
    const { stateController } = this
    const filter = this.filterNameValue
    const form_id = stateController.formIdValue
    let put_data = JSON.stringify({
      blueprint,
      filter,
      form_id
    })
    let token = document.querySelector("meta[name='csrf-token']")?.content
    const response = await fetch(this.updateStableIdUrlValue, {
      method: 'PUT',
      body: put_data,
      headers: {
        accept: 'application/json',
        'content-type': 'application/json',
        'X-CSRF-Token': token,
      },
    })
    const responseJson = await response.json()
    if (response.ok) {
      return { stableId: responseJson.filter_id}
    } else {
      const errors = responseJson.errors
      return {errors}
    }
  }

  get stateController() {
    return this.element.querySelector('[data-controller~=refine--state]')
  }
}
