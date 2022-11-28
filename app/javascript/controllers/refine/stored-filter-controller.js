import { Controller } from "@hotwired/stimulus"
import { filterStoredEvent } from '../../refine/helpers'

export default class extends Controller {
  static targets = ['blueprintField']
  static values = { id: Number, stableId: String, filterName: String, formId: String, blueprint: Array }

  connect() {
    if (this.idValue) {
      filterStoredEvent(this.idValue)
    }
  }

  updateBlueprintField(event) {
    if (event.detail.formId != this.formIdValue) { return null }
    const { detail } = event
    const { blueprint } = detail
    this.blueprintValue = blueprint
    if (this.hasBlueprintFieldTarget) {
      this.blueprintFieldTarget.value = blueprint
    }
  }

  setBlueprintFieldFromValue(event) {
    if (this.hasBlueprintFieldTarget) {
      this.blueprintFieldTarget.value = JSON.stringify(this.blueprintValue)
    }
  }
}
