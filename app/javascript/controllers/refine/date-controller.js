import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
require("flatpickr/dist/flatpickr.css")

/*
  Stimulus controller for initializing the datepicker.
  It defaults to flatpickr, but end-users can customize it by specifying the following:
  window.HammerstoneRefine.datePicker = {
    connect: function() {}, // runs bound to the Stimulus Controller instance at connect
    disconnect: function() {}, // runs bound to the Stimulus Controller instance at disconnect
  }
*/
export default class extends Controller {
  static targets = [
    'field',
    'hiddenField'
  ]

  connect() {
    if (window.HammerstoneRefine?.datePicker) {
      window.HammerstoneRefine.datePicker.connect.bind(this)()
    } else {
      this.defaultConnect()
    }
  }

  disconnect() {
    if (window.HammerstoneRefine?.datePicker) {
      window.HammerstoneRefine.datePicker.disconnect.bind(this)()
    } else {
      this.defaultDisconnect()
    }
  }

  defaultConnect() {
    this.plugin = flatpickr(this.fieldTarget,{
      minDate: this.futureOnlyValue ? new Date() : null,
      dateFormat: 'm/d/Y',
      onChange: (selectedDates, dateStr, instance) => {
        const format = this.includeTimeValue ? 'm/d/Y h:i K' : 'm/d/Y'
        this.fieldTarget.value = instance.formatDate(selectedDates[0], format)
        this.hiddenFieldTarget.value = instance.formatDate(selectedDates[0], 'Y-m-d')
        this.hiddenFieldTarget.dispatchEvent(new Event('change', {bubbles: true}))
      }
    })
  }

  defaultDisconnect() {
    this.plugin.destroy()
  }
}
