import FormController from './form-controller'

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
