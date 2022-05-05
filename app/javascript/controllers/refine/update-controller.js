import FormController from './form-controller'
import { debounce } from 'lodash'

export default class extends FormController {
  static values = {
    criterionId: Number,
    stableId: String
  }

  initialize() {
    this.updateBlueprint = debounce((event, value, inputKey) => {
      this.value(event, value, inputKey)
      this.createStableId(this.state.blueprint, this.state.filterName)
    }, 500)
  }

  connect() {
    FormController.prototype.connect.apply(this)
    this.state.updateStableId(this.stableIdValue)
  }

  refinedFilter(event) {
    const { criterionIdValue, state } = this
    const dataset = event.target.dataset
    const inputId = dataset.inputId

    state.updateInput(
      criterionIdValue,
      {
        id: event.target.value,
      },
      inputId
    )
    this.submitForm()
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
    this.createStableId(this.state.blueprint, this.state.filterName)
  }

  value(event, value, inputKey) {
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

  date(event) {
    const { picker } = event.detail
    const value = picker.startDate.format('YYYY-MM-DD')
    this.value(event, value)
    this.submitForm()
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

  condition(event) {
    const { criterionIdValue, state } = this
    const element = event.target
    const newConditionId = element.value
    const config = this.state.conditionConfigFor(newConditionId)
    state.replaceCriterion(criterionIdValue, newConditionId, config)
    this.submitForm()
  }
}
