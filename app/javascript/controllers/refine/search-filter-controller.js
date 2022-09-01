import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static values = {
    submitUrl: String
  }

  static targets = []

  connect() {
    const urlParams = new URLSearchParams(window.location.search)
    this.existingParams = urlParams
    this.existingParams.delete('stable_id')
  }

  search(event) {
    event.preventDefault()
    this.submitFilter()
    document.activeElement.blur()
  }

  async submitFilter() {
    const {blueprint} = this.stateController
    const validationResult = await this.stabilizeFilterController.validateBlueprint(blueprint)
    if (validationResult.stableId) {
      this.redirectToStableId(validationResult.stableId)
    } else {
      this.fetchAndRenderInvalidFilter(blueprint)
    }
  }

  addHiddenInput({name, value}) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = name
    input.value = value
    this.submissionFormTarget.appendChild(input)
  }

  get stateController() {
    return this
      .element
      .querySelector('[data-controller~="refine--state"]')
      .refineStateController
  }

  get stabilizeFilterController() {
    return this
     .element
     .stabilizeFilterController
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

  async fetchAndRenderInvalidFilter(blueprint) {
    const request = new FetchRequest(
      "POST",
      this.submitUrlValue,
      {
        responseKind: "turbo-stream",
        body: JSON.stringify({
          filter: this.stateController.filterName,
          blueprint: JSON.stringify(blueprint),
          id_suffix: this.stateController.idSuffix
        })
      }
    )
    await request.perform()
  }
}
