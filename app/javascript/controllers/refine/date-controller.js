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
    const localeCode = ( this.localeValue?.slice(0,2) || "en" )
    this.plugin = flatpickr(this.fieldTarget, {
      minDate: this.futureOnlyValue ? new Date() : null,
      dateFormat: 'YYYY-MM-DD',
      locale: locales[localeCode],
      defaultDate: this.hiddenFieldTarget.value,
      parseDate: (datestr, format) => {import { Controller } from "@hotwired/stimulus"
      import moment from 'moment'
      require('daterangepicker/daterangepicker.css')
      
      // requires jQuery, moment, might want to consider a vanilla JS alternative
      import $ from 'jquery' // ensure jquery is loaded before daterangepicker
      import 'daterangepicker'
      
      export default class extends Controller {
        static targets = [
          'field',
          'clearButton',
          'currentTimeZoneField',
          'currentTimeZoneWrapper',
          'timeZoneButtons',
          'timeZoneSelectWrapper',
          'timeZoneField',
        ]
      
        static values = {
          includeTime: Boolean,
          defaultTimeZones: Array,
          futureOnly: Boolean,
          drops: String,
          inline: Boolean,
          cancelButtonLabel: { type: String, default: 'Cancel' },
          applyButtonLabel: { type: String, default: 'Apply' },
        }
      
        connect() {
          this.initPluginInstance()
        }
      
        disconnect() {
          this.teardownPluginInstance()
        }
      
        clearDate(event) {
          // don't submit the form, unless it originated from the cancel/clear button
          event.preventDefault()
      
          window.$(this.fieldTarget).val('')
      
          this.dispatch('value-cleared')
        }
      
        applyDateToField(event, picker) {
          const format = this.includeTimeValue ? 'MM/DD/YYYY h:mm A' : 'MM/DD/YYYY'
          console.log("Setting applyDateToField")
          console.log(picker)
          window.$(this.fieldTarget).val(picker.startDate.format(format))
          // bubble up a change event when the input is updated for other listeners
          window.$(this.fieldTarget).trigger('change', picker)
      
          // emit native change event
          this.element.dispatchEvent(new Event('change', { detail: picker, bubbles: true }))
        }
      
        showTimeZoneButtons(event) {
          // don't follow the anchor
          event.preventDefault()
      
          $(this.currentTimeZoneWrapperTarget).toggleClass('hidden')
          $(this.timeZoneButtonsTarget).toggleClass('hidden')
        }
      
        showTimeZoneSelectWrapper(event) {
          // don't follow the anchor
          event.preventDefault()
      
          $(this.timeZoneButtonsTarget).toggleClass('hidden')
      
          if (this.hasTimeZoneSelectWrapperTarget) {
            $(this.timeZoneSelectWrapperTarget).toggleClass('hidden')
          }
        }
      
        resetTimeZoneUI(e) {
          e && e.preventDefault()
      
          $(this.currentTimeZoneWrapperTarget).removeClass('hidden')
          $(this.timeZoneButtonsTarget).addClass('hidden')
      
          if (this.hasTimeZoneSelectWrapperTarget) {
            $(this.timeZoneSelectWrapperTarget).addClass('hidden')
          }
        }
      
        setTimeZone(event) {
          // don't follow the anchor
          event.preventDefault()
      
          const currentTimeZoneField = this.currentTimeZoneWrapperTarget.querySelector('span')
          const { value } = event.target.dataset
      
          $(this.timeZoneFieldTarget).val(value)
          $(currentTimeZoneField).text(value)
      
          $('.time-zone-button').removeClass('button').addClass('button-alternative')
          $(event.target).removeClass('button-alternative').addClass('button')
      
          this.resetTimeZoneUI()
        }
      
        initPluginInstance() {
          // this.getFieldSelector().daterangepicker({
          window.$(this.fieldTarget).daterangepicker({
            singleDatePicker: true,
            timePicker: this.includeTimeValue,
            timePickerIncrement: 5,
            autoUpdateInput: false,
            autoApply: true,
            minDate: this.futureOnlyValue ? new Date() : false,
            locale: {
              cancelLabel: this.cancelButtonLabelValue,
              applyLabel: this.applyButtonLabelValue,
              format: this.includeTimeValue ? 'MM/DD/YYYY h:mm A' : 'MM/DD/YYYY',
            },
            parentEl: $(this.element),
            drops: this.dropsValue ? this.dropsValue : 'down',
          })
      
          window.$(this.fieldTarget).on('apply.daterangepicker', this.applyDateToField.bind(this))
          window.$(this.fieldTarget).on('cancel.daterangepicker', this.clearDate.bind(this))
          window.$(this.fieldTarget).on('showCalendar.daterangepicker', this.showCalendar.bind(this))
      
          this.pluginMainEl = this.fieldTarget
          this.plugin = $(this.pluginMainEl).data('daterangepicker') // weird
      
          if (this.inlineValue) {
            this.element.classList.add('date-input--inline')
          }
      
          // Init time zone select
          if (this.includeTimeValue && this.hasTimeZoneSelectWrapperTarget) {
            this.timeZoneSelect = this.timeZoneSelectWrapperTarget.querySelector('select.select2')
      
            $(this.timeZoneSelect).select2({
              width: 'style',
            })
      
            $(this.timeZoneSelect).on('change.select2', (event) => {
              const currentTimeZoneField = this.currentTimeZoneWrapperTarget.querySelector('span')
              const { value } = event.target
      
              $(this.timeZoneFieldTarget).val(value)
              $(currentTimeZoneField).text(value)
      
              const selectedOptionTimeZoneButton = $('.selected-option-time-zone-button')
      
              $('.time-zone-button').removeClass('button').addClass('button-alternative')
      
              if (this.defaultTimeZonesValue.includes(value)) {
                selectedOptionTimeZoneButton.addClass('hidden').attr('hidden', true)
                $(`a[data-value="${value}"`).removeClass('button-alternative').addClass('button')
              } else {
                // deselect any selected button
                selectedOptionTimeZoneButton.text(value)
                selectedOptionTimeZoneButton.attr('data-value', value).removeAttr('hidden')
                selectedOptionTimeZoneButton.removeClass(['hidden', 'button-alternative']).addClass('button')
              }
      
              this.resetTimeZoneUI()
            })
          }
        }
      
        teardownPluginInstance() {
          if (this.plugin === undefined) {
            return
          }
      
          $(this.pluginMainEl).off('apply.daterangepicker')
          $(this.pluginMainEl).off('cancel.daterangepicker')
          $(this.pluginMainEl).off('showCalendar.daterangepicker')
      
          // revert to original markup, remove any event listeners
          this.plugin.remove()
      
          if (this.includeTimeValue) {
            $(this.timeZoneSelect).select2('destroy')
          }
        }
      
        showCalendar() {
          this.dispatch('show-calendar')
        }
      
      }
      
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
