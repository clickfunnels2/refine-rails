import { Controller } from "@hotwired/stimulus"
import { filterStoredEvent } from '../../refine/helpers'

export default class extends Controller {
  static targets = ['blueprintField']
  static values = { formId: String }

  connect() {
    const stateController = document
      .getElementById(`query_hammerstone_refine_filter_forms_form_${this.formIdValue}`)
      .refineStateController
    this.blueprintFieldTarget.value = JSON.stringify(stateController.blueprint)
    console.log("connect", this.blueprintFieldTarget.value)
  }

  updateBlueprintField(event) {
    if (event.detail.formId != this.formIdValue) { return null }
    const { detail } = event
    const { blueprint } = detail
    this.blueprintFieldTarget.value = JSON.stringify(blueprint)
    console.log("update blueprint", this.blueprintFieldTarget.value)
  }
}
