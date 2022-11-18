import { Controller } from "@hotwired/stimulus"
import { filterStoredEvent } from '../../refine/helpers'

export default class extends Controller {
  static targets = ['stableIdField']
  static values = { id: Number, stableId: String, filterName: String }

  connect() {
    if (this.idValue) {
      filterStoredEvent(this.idValue)
    }
  }

  updateStableIdField(event) {
    if (event.detail.filterName != this.filterNameValue) { return null }
    if (this.hasStableIdFieldTarget) {
      const { detail } = event
      const { stableId } = detail
      this.stableIdFieldTarget.value = stableId
    }
  }
}
