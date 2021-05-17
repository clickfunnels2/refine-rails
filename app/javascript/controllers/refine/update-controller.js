import FormController from './form-controller';

export default class extends FormController {
  static values = {
    criterionId: Number,
  };

  option(event) {
    const { criterionIdValue, state } = this;
    const selectElement = event.target;
    const selected = [];

    // do this instead of selectedOptions to support IE
    for (var i = 0; i < selectElement.length; i++) {
      if (selectElement.options[i].selected) selected.push(selectElement.options[i].value);
    }

    state.update(
      criterionIdValue,
      selected,
    );
  }

  clause(event) {
    const { criterionIdValue, state } = this;

    state.updateInput(
      criterionIdValue, {
        clause: event.target.value,
      });

    this.submitForm();
  }

  selected(event) {
    const { target: select } = event;
    const options = Array.prototype.slice.call(select.options);
    const selectedOptions = options.filter(option => option.selected);
    const selected = selectedOptions.map(option => option.value);

    this.value(event, selected, 'selected');
  }

  date(event) {
    const { picker } = event.detail;
    const value = picker.startDate.format('YYYY-MM-DD');
    this.value(event, value);
  }

  value(event, value, inputKey) {
    const { criterionIdValue, state } = this;
    inputKey = inputKey || event.target.dataset.inputKey || 'value';
    value = value || event.target.value;

    state.updateInput(
      criterionIdValue, {
        [inputKey]: value,
      });
  }

  condition(event) {
    const { criterionIdValue, state } = this;
    const element = event.target;
    const newConditionId = element.value;
    const config = this.state.conditionConfigFor(newConditionId);

    // set selected clause to the first clause by default
    const newInput = {
      clause: config.meta.clauses[0].id,
    };

    state.updateConditionId(
      criterionIdValue,
      newConditionId,
    );

    state.replaceInput(
      criterionIdValue,
      newInput,
    );

    this.submitForm();
  }
}
