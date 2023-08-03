import { Controller } from "@hotwired/stimulus"
import moment from 'moment'
import flatpickr from "flatpickr"
require("flatpickr/dist/flatpickr.css")
import { english } from "flatpickr/dist/l10n/default.js"
import { Spanish } from "flatpickr/dist/l10n/es.js"
import { Portuguese } from "flatpickr/dist/l10n/pt.js"

const locales  = {
  "en": english,
  "es": Spanish,
  "pt": Portuguese
}

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

  static values = {
    locale: { type: String, default: 'en' },
    dateFormat: { type: String, default:  'MM/DD/YYYY' },
    datetimeFormat: { type: String, default:  'MM/DD/YYYY h:mm A' },
  }

  connect() {
    window.HammerstoneRefine ||= {}
    window.HammerstoneRefine.locale = this.localeValue
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
    const localeCode = window.HammerstoneRefine.locale.slice(0,2)
    this.plugin = flatpickr(this.fieldTarget, {
      minDate: this.futureOnlyValue ? new Date() : null,
      dateFormat: 'YYYY-MM-DD',
      locale: locales[localeCode],
      defaultDate: this.hiddenFieldTarget.value,
      parseDate: (datestr, format) => {
        return moment(datestr, format, true).toDate()
      },
      formatDate: (date, format) => {
        const momentDate = moment(date)
        return momentDate.format(format)
      },
      onChange: (selectedDates, dateStr, instance) => {
        const format = this.includeTimeValue ? this.datetimeFormatValue : this.dateFormatValue
        // display format
        this.fieldTarget.value = instance.formatDate(selectedDates[0], format)
        // internal format saved in db
        this.hiddenFieldTarget.value = instance.formatDate(selectedDates[0], 'YYYY-MM-DD')
        this.hiddenFieldTarget.dispatchEvent(new Event('change', { bubbles: true }))
      },
      onReady: [
        () => {
          const momentDate = moment(this.hiddenFieldTarget.value)
          if (momentDate.isValid()) {
            const format = this.includeTimeValue ? this.datetimeFormatValue : this.dateFormatValue
            this.fieldTarget.value = momentDate.format(format)
          }
        },
      ],
    })
  }

  defaultDisconnect() {
    this.plugin.destroy()
  }
}
