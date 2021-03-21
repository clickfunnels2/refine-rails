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

  value(event) {
    const { criterionIdValue, state } = this;

    // TODO add input key here as data attribute to not
    // hard code the key to 'value'
    state.updateInput(
      criterionIdValue, {
        value: event.target.value,
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
