import ServerRefreshController from './server-refresh-controller'
import { debounce } from 'lodash'

export default class extends ServerRefreshController {
  static values = {
    criterionId: Number,
  }

  initialize() {
    this.updateBlueprint = debounce((event, value, inputKey) => {
      this.value(event, value, inputKey)
    }, 500)
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
    this.refreshFromServer()
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
    this.refreshFromServer()
  }

  selected(event) {
    const { target: select } = event
    const options = Array.prototype.slice.call(select.options)
    const selectedOptions = options.filter((option) => option.selected)
    const selected = selectedOptions.map((option) => option.value)
    this.value(event, selected, 'selected')
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
    const format = this.includeTimeValue ? 'MM/DD/YYYY h:mm A' : 'MM/DD/YYYY'
    const value = picker.startDate.format(format)
    console.log("Handling update-controller value")
    console.log(event)
    console.log(value)
    this.value(event, value)
    this.refreshFromServer()
  }

  condition(event) {
    const { criterionIdValue, state } = this
    const element = event.target
    let newConditionId = element.value
    if (!newConditionId) newConditionId = element.querySelector('select').value    
    const config = this.state.conditionConfigFor(newConditionId)
    const updatePerformed = state.replaceCriterion(criterionIdValue, newConditionId, config)
    if (updatePerformed) {
      this.refreshFromServer()
    }
  }

  // Prevent form submission when hitting enter in a text box
  cancelEnter(event) {
    if (event.code === "Enter") {
      event.preventDefault()
      event.stopPropagation()
    }
  }
}
