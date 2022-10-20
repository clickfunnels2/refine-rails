import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
require("flatpickr/dist/flatpickr.css")

export default class extends Controller {
  static targets = [
    'field',
  ]
  static values = {
    includeTime: Boolean,
  }

  connect() {
    // init plugin
    window.HammerstoneRefine.datePicker.connect.bind(this)()
  }

  disconnect() {
    window.HammerstoneRefine.datePicker.disconnect.bind(this)()
  }
}

/*
  Logic for the actual datepicker lives in a window variable.
  This allows end-users to customize it by specifying the following:
  window.HammerstoneRefine.datePicker = {
    connect: function() {}, // runs bound to the Stimulus Controller instance at connect
    disconnect: function() {}, // runs bound to the Stimulus Controller instance at disconnect
    format: 'm/d/y' // date format in flatpickr tokens (see https://flatpickr.js.org/formatting/)
  }
*/
window.HammerstoneRefine ||= {}
window.HammerstoneRefine.datePicker || (window.HammerstoneRefine.datePicker = {
  connect: function() {
    this.plugin = flatpickr(this.fieldTarget,{
      enableTime: this.includeTimeValue,
      minDate: this.futureOnlyValue ? new Date() : null,
      dateFormat: this.includeTimeValue ? 'm/d/Y h:i K' : 'm/d/Y',
      onChange: (selectedDates, dateStr, instance) => {
        const format = this.includeTimeValue ? 'm/d/Y h:i K' : 'm/d/Y'
        this.fieldTarget.value = instance.formatDate(selectedDates[0], format)
      }
    })
  },
  disconnect: function() {
    this.plugin.destroy()
  },
  format: 'm/d/Y'
})
