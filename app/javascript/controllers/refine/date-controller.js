import { Controller } from "@hotwired/stimulus"
import moment from 'moment'
require('daterangepicker/daterangepicker.css')

// requires jQuery, moment, might want to consider a vanilla JS alternative
import $ from 'jquery' // ensure jquery is loaded before daterangepicker
import 'daterangepicker'

export default class extends Controller {
  static targets = [
    'field',
    'hiddenField',
    'clearButton',
  ]

  static values = {
    includeTime: Boolean,
    futureOnly: Boolean,
    drops: String,
    inline: Boolean,
    dateFormat: String,
    timeFormat: String,
    isAmPm: Boolean,
    locale: { type: String, default: 'en' },
    datetimeFormat: { type: String, default:  'MM/DD/YYYY h:mm A' },
    pickerLocale: { type: Object, default: {} },
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
    const format = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue

    const momentVal = picker
      ? moment(picker.startDate.toISOString())
      : moment(this.fieldTarget.value, 'YYYY-MM-DDTHH:mm').format('YYYY-MM-DDTHH:mm')
    const displayVal = momentVal.format(format)
    const dataVal = this.includeTimeValue ? momentVal.toISOString(true) : momentVal.format('YYYY-MM-DD')

    this.fieldTarget.value = displayVal
    this.hiddenFieldTarget.value = dataVal
    // bubble up a change event when the input is updated for other listeners
    window.$(this.fieldTarget).trigger('change', picker)

    // emit native change event
    this.hiddenFieldTarget.dispatchEvent(new Event('change', { detail: picker, bubbles: true }))
  }

  initPluginInstance() {
    const localeValues = this.pickerLocaleValue
    const isAmPm = this.isAmPmValue
    localeValues['format'] = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue

    window.$(this.fieldTarget).daterangepicker({
      singleDatePicker: true,
      timePicker: this.includeTimeValue,
      timePickerIncrement: 5,
      autoUpdateInput: false,
      autoApply: true,
      minDate: this.futureOnlyValue ? new Date() : false,
      locale: localeValues,
      parentEl: $(this.element),
      drops: this.dropsValue ? this.dropsValue : 'down',
      timePicker24Hour: !isAmPm,
    })

    window.$(this.fieldTarget).on('apply.daterangepicker', this.applyDateToField.bind(this))
    window.$(this.fieldTarget).on('cancel.daterangepicker', this.clearDate.bind(this))
    window.$(this.fieldTarget).on('showCalendar.daterangepicker', this.showCalendar.bind(this))

    this.pluginMainEl = this.fieldTarget
    this.plugin = $(this.pluginMainEl).data('daterangepicker') // weird

    if (this.inlineValue) {
      this.element.classList.add('date-input--inline')
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

  }

  showCalendar() {
    this.dispatch('show-calendar')
  }

}
