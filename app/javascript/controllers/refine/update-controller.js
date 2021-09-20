import FormController from './form-controller'
import { debounce } from 'lodash'
import { filterUnstableEvent, filterStabilizedEvent } from 'refine/helpers'

export default class extends FormController {
  static values = {
    criterionId: Number,
    stableId: String,
  }

  connect() {
    FormController.prototype.connect.apply(this)
    this.state.updateStableId(this.stableIdValue)
  }

  clause(event) {
    const { criterionIdValue, state } = this
    const dataset = event.target.dataset
    const inputId = dataset.inputId

    state.updateInput(
      criterionIdValue,
      {
        clause: event.target.value,
      },
      inputId
    )
    this.submitForm()
  }

  selected(event) {
    const { target: select } = event
    const options = Array.prototype.slice.call(select.options)
    const selectedOptions = options.filter((option) => option.selected)
    const selected = selectedOptions.map((option) => option.value)

    this.value(event, selected, 'selected')
  }

  date(event) {
    const { picker } = event.detail
    const value = picker.startDate.format('YYYY-MM-DD')
    this.value(event, value)

    this.submitForm()
  }

  updateBlueprint(event, value, inputKey) {
    const debouncedCreateStableId = debounce((event, value, inputKey) => {
      this.value(event, value, inputKey)
      this.createStableId(this.state.blueprint, this.state.filterName)
    }, 500)

    debouncedCreateStableId(event, value, inputKey)
  }

  createStableId(blueprint, filter) {
    // Create stableId on debounced input and update stable id to allow for form submission
    const { state } = this
    let post_data = JSON.stringify({ blueprint, filter })
    let token = document.querySelector("meta[name='csrf-token']").content
    $.ajax({
      type: 'PUT',
      url: '/hammerstone/update_stable_id',
      data: post_data,
      headers: {
        accept: 'application/json',
        'content-type': 'application/json',
        'X-CSRF-Token': token,
      },
      success: function (e) {
        state.updateStableId(e.filter_id)
      },
    })
  }

  value(event, value, inputKey) {
    // Updates state with value
    const { criterionIdValue, state } = this
    const dataset = event.target.dataset
    const inputId = dataset.inputId

    inputKey = inputKey || dataset.inputKey || 'value'
    value = value || event.target.value

    state.updateInput(
      criterionIdValue,
      {
        [inputKey]: value,
      },
      inputId
    )
  }

  condition(event) {
    const { criterionIdValue, state } = this
    const element = event.target
    const newConditionId = element.value
    const config = this.state.conditionConfigFor(newConditionId)

    // set selected clause to the first clause by default
    const newInput = {
      clause: config.meta.clauses[0].id,
    }

    state.updateConditionId(criterionIdValue, newConditionId)

    state.replaceInput(criterionIdValue, newInput)

    this.submitForm()
  }
}
