import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static values = {
    submitUrl: String
  }

  static targets = []

  connect() {
    console.log("Seacrch filter connected!")
    const urlParams = new URLSearchParams(window.location.search)
    this.existingParams = urlParams
    this.existingParams.delete('stable_id')
  }

  search(event) {
    console.log("search!")
    event.preventDefault()
    this.submitFilter()
    document.activeElement.blur()
  }

  async submitFilter() {
    const {blueprint} = this.stateController
    const validationResult = await this.stabilizeFilterController.validateBlueprint(blueprint)
    console.log('validationResult', validationResult)
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
    console.log('this.submitUrlValue', this.submitUrlValue)
    const response = await fetch(this.submitUrlValue, {
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content
      },
      method: "POST",
      body: JSON.stringify({
        filter: this.stateController.filterName,
        blueprint: JSON.stringify(blueprint),
        id_suffix: this.stateController.idSuffix
      })
    })

    const responseData = await response.json()
    const element = document.getElementById(responseData.target)
    element.outerHTML = responseData.template
  }
}
