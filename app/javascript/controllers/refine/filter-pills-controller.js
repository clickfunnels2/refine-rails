import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    const urlParams = new URLSearchParams(window.location.search)
    this.existingParams = urlParams
    this.existingParams.delete('stable_id')
  }

  delete(event) {
    const { criterionId } = event.currentTarget.dataset
    this.stateController.deleteCriterion(criterionId)
    this.reloadPage()
  }

  async reloadPage() {
    const {blueprint} = this.stateController
    const validationResult = await this.stabilizeFilterController.validateBlueprint(blueprint)
    if (validationResult.stableId) {
      this.redirectToStableId(validationResult.stableId)
    }
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
