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
    'currentTimeZoneField',
    'currentTimeZoneWrapper',
    'timeZoneButtons',
    'timeZoneSelectWrapper',
    'timeZoneField',
    'timeZoneSelect',
  ]

  static values = {
    includeTime: Boolean,
    defaultTimeZones: Array,
    futureOnly: Boolean,
    drops: String,
    inline: Boolean,
    dateFormat: String,
    timeFormat: String,
    currentTimeZone: String,
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
    const newTimeZone = this.currentTimeZone()

    const momentVal = picker
      ? moment(picker.startDate.toISOString()).tz(newTimeZone, true)
      : moment.tz(moment(this.fieldTarget.value, 'YYYY-MM-DDTHH:mm').format('YYYY-MM-DDTHH:mm'), newTimeZone)
    const displayVal = momentVal.format(format)
    const dataVal = this.includeTimeValue ? momentVal.toISOString(true) : momentVal.format('YYYY-MM-DD')

    this.fieldTarget.value = displayVal
    this.hiddenFieldTarget.value = dataVal
    // bubble up a change event when the input is updated for other listeners
    window.$(this.fieldTarget).trigger('change', picker)

    // emit native change event
    this.hiddenFieldTarget.dispatchEvent(new Event('change', { detail: picker, bubbles: true }))
  }

  showTimeZoneButtons(event) {
    // don't follow the anchor
    event.preventDefault()

    $(this.currentTimeZoneWrapperTarget).toggleClass('hidden')
    $(this.timeZoneButtonsTarget).toggleClass('hidden')
  }

  // triggered on other click from the timezone buttons
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

  // triggered on selecting a new timezone using the buttons
  setTimeZone(event) {
    // don't follow the anchor
    event.preventDefault()

    const currentTimeZoneEl = this.currentTimeZoneWrapperTarget.querySelector('span')
    $(this.timeZoneFieldTarget).val(event.target.dataset.value)
    $(currentTimeZoneEl).text(event.target.dataset.label)

    $('.time-zone-button').removeClass('button').addClass('button-alternative')
    $(event.target).removeClass('button-alternative').addClass('button')

    this.resetTimeZoneUI()
  }

  // triggered on cancel click from the timezone picker
  cancelSelect(event) {
    event.preventDefault()
    this.resetTimeZoneUI()
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

  currentTimeZone() {
    return (
      (this.hasTimeZoneSelectWrapperTarget &&
        $(this.timeZoneSelectWrapperTarget).is(':visible') &&
        this.timeZoneSelectTarget.value) ||
      (this.hasTimeZoneFieldTarget && this.timeZoneFieldTarget.value) ||
      this.currentTimeZoneValue
    )
  }

}
