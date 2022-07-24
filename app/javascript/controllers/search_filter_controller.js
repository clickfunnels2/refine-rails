import { Controller } from '@hotwired/stimulus'
export default class extends Controller {
  static values = {
    submitUrl: String
  }

  static targets = []

  connect() {
    const urlParams = new URLSearchParams(window.location.search)
    this.existingParams = urlParams
    this.paramsCache = {
      stable_id: urlParams.get('stable_id'),
    }
    this.existingParams.delete('stable_id')
    this.stableId = this.paramsCache['stable_id']
  }

  updateStableId(event) {
    const {
      detail: { stableId },
    } = event

    this.stableId = stableId
  }

  search(event) {
    event.preventDefault()
    this.submitFilter()
    document.activeElement.blur()
  }

  async submitFilter() {
    const response = await fetch(this.submitUrlValue, {
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content
      },
      method: "POST",
      body: JSON.stringify({
        filter: this.stateController.filterName,
        blueprint: JSON.stringify(this.stateController.blueprint),
        id_suffix: this.stateController.idSuffix
      })
    })

    if (response.ok) {
      const responseData = await response.json()
      this.stableId = responseData.filter_id
      history.pushState({}, document.title, this.urlForRedirect())
      window.location.reload()
    } else {
      const responseData = await response.json()
      const element = document.getElementById(responseData.target)
      element.outerHTML = responseData.template
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
      .querySelector('[data-controller="refine--state"]')
      .refineStateController
  }

  urlForRedirect() {
    const params = new URLSearchParams()
    if (this.stableId) {
      params.append('stable_id', this.stableId)
    }
    const allParams = new URLSearchParams({
      ...Object.fromEntries(this.existingParams),
      ...Object.fromEntries(params),
    }).toString()
    return `${window.location.pathname}?${allParams}`
  }
}