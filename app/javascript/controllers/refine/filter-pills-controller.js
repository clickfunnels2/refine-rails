import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static values = {
    submitUrl: String
  }

  connect() {
    const urlParams = new URLSearchParams(window.location.search)
    this.existingParams = urlParams
    this.existingParams.delete('stable_id')
  }

  delete(event) {
    const { criterionId } = event.currentTarget.dataset
    var index = parseInt(criterionId)
    this.stateController.deleteCriterion(index)
    this.reloadPage()
  }

  async reloadPage() {
    const {blueprint} = this.stateController
    const request = new FetchRequest(
      "POST",
      this.submitUrlValue,
      {
        responseKind: "turbo-stream",
        body: JSON.stringify({
          hammerstone_refine_filters_builder: {
            filter_class: this.stateController.filterName,
            blueprint_json: JSON.stringify(blueprint),
            client_id: this.stateController.clientIdValue
          }
        })
      }
    )
    await request.perform()
  }

  redirectToStableId(stableId) {
    const params = new URLSearchParams()
    if (stableId) {
      params.append('stable_id', stableId)
    }
    const allParams = new URLSearchParams({
      ...Object.fromEntries(this.existingParams),
      ...Object.fromEntries(params),
    }).toString()
    const url = `${window.location.pathname}?${allParams}`

    history.pushState({}, document.title, url)
    window.location.reload()
  }

  get stateController() {
    return this.element.refineStateController
  }

  get stabilizeFilterController() {
    return this.element.stabilizeFilterController
  }
}
