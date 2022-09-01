import { Controller } from "@hotwired/stimulus"
import { filterStoredEvent } from '../../refine/helpers'

export default class extends Controller {
  static targets = ['enabledSaveLink', 'disabledSaveLink', 'stableIdField']
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

  activateSaveLink(event) {
    const { detail } = event
    const { stableId } = detail

    if (event.detail.filterName != this.filterNameValue) { return null }
    if (this.hasEnabledSaveLinkTarget && this.hasDisabledSaveLinkTarget) {
      const saveUrl = new URL(this.enabledSaveLinkTarget.href)
      saveUrl.searchParams.set('stable_id', stableId)
      this.enabledSaveLinkTarget.setAttribute('href', saveUrl)
      this.disabledSaveLinkTarget.classList.add('hidden')
      this.enabledSaveLinkTarget.classList.remove('hidden')
    }
  }
}
