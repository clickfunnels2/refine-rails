import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import $ from 'jquery' // ensure jquery is loaded before daterangepicker

export default class extends Controller {
  static targets = [
    'field',
    'clearButton',
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
    cancelButtonLabel: { type: String, default: 'Cancel' },
    applyButtonLabel: { type: String, default: 'Apply' },
  }

  connect() {
    // init plugin
    console.log("init flatpickr on ", this.fieldTarget)
    this.plugin = flatpickr(this.fieldTarget,{
      enableTime: this.includeTimeValue,
      minDate: this.futureOnlyValue ? new Date() : null,
      dateFormat: this.includeTimeValue ? 'MM/DD/YYYY h:mm A' : 'MM/DD/YYYY',
      onChange: (selectedDates, dateStr, instance) => {
        const format = this.includeTimeValue ? 'MM/DD/YYYY h:mm A' : 'MM/DD/YYYY'
        this.fieldTarget.value = selectedDates[0].format(format)
        // bubble up a change event when the input is updated for other listeners
        const changeEvent = new Event('change', {bubbles: true})
        this.fieldTarget.dispatchEvent(changeEvent)
      },
      onClose: (selectedDates, dateStr, instance) => {
        console.log("flatpickr close!")
        this.fieldTarget.value = ''
      }
    })


    // Init time zone select
    /*
      TODO Clarify who uses time zones
      Markup for selecting timze zones is not present in the gem code.
      Clarify whether end-users should handle it
      Could also provide a plugin system with this as the default
    */
    if (this.includeTimeValue && this.hasTimeZoneSelectWrapperTarget) {
      this.timeZoneSelect = this.timeZoneSelectWrapperTarget.querySelector('select.select2')

      $(this.timeZoneSelect).select2({
        width: 'style',
      })

      $(this.timeZoneSelect).on('change.select2', (event) => {
        const currentTimeZoneEl = this.currentTimeZoneWrapperTarget.querySelector('a')
        const { value } = event.target

        this.timeZoneFieldTarget.value = value
        currentTimeZoneEl.textContent = value

        // FIXME this should be scoped
        const selectedOptionTimeZoneButton = document.querySelector('.selected-option-time-zone-button')

        if (this.defaultTimeZonesValue.includes(value)) {
          $('.time-zone-button').removeClass('button').addClass('button-alternative')
          selectedOptionTimeZoneButton.addClass('hidden').attr('hidden', true)
          $(`a[data-value="${value}"`).removeClass('button-alternative').addClass('button')
        } else {
          // deselect any selected button
          $('.time-zone-button').removeClass('button').addClass('button-alternative')

          selectedOptionTimeZoneButton.textContent = value
          selectedOptionTimeZoneButton.dataset.value =  value
          selectedOptionTimeZoneButton.removeAttribute('hidden')
          selectedOptionTimeZoneButton.classList.remove('hidden')
          selectedOptionTimeZoneButton.classList.remove('button-alternative')
          selectedOptionTimeZoneButton.classList.add('button')
        }

        this.resetTimeZoneUI()
      })
    }
  }

  disconnect() {
    console.log("Cleaning up flatpickr")
    this.plugin.destroy()

    if (this.includeTimeValue) {
      $(this.timeZoneSelect).select2('destroy')
    }
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

    const currentTimeZoneEl = this.currentTimeZoneWrapperTarget.querySelector('a')
    const { value } = event.target.dataset

    $(this.timeZoneFieldTarget).val(value)
    $(currentTimeZoneEl).text(value)

    $('.time-zone-button').removeClass('button').addClass('button-alternative')
    $(event.target).removeClass('button-alternative').addClass('button')

    this.resetTimeZoneUI()
  }
}
