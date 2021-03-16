import { Controller } from "stimulus";
import { delegate } from 'jquery-events-to-dom-events';

// Polyfill for custom events in IE9-11
// https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent#polyfill
(function () {

  if ( typeof window.CustomEvent === "function" ) return false;

  function CustomEvent ( event, params ) {
    params = params || { bubbles: false, cancelable: false, detail: undefined };
    var evt = document.createEvent('CustomEvent');
    evt.initCustomEvent( event, params.bubbles, params.cancelable, params.detail );
    return evt;
  }

  CustomEvent.prototype = window.Event.prototype;

  window.CustomEvent = CustomEvent;

  // eslint expects a return here
  return true;
})();

const createCriterion = (id, depth, meta) => {
  return {
    depth,
    type: 'criterion',
    condition_id: id,
    input: { clause: meta.clauses[0].id },
  };
};

const or = function(depth) {
  depth = depth === undefined ? 0 : depth;
  return {
    depth,
    type: 'conjunction',
    word: 'or',
  };
};

const blueprintUpdatedEvent = (blueprint, filterName) => {
  const event = new CustomEvent('blueprint-updated', {
    detail: {
      blueprint: JSON.parse(JSON.stringify(blueprint)),
      filterName,
    }});
  window.dispatchEvent(event);
};

export default class extends Controller {
  static values = {
    configuration: Object,
  }

  connect() {
    delegate('change');
    this.configuration = { ...this.configurationValue };
    this.blueprint = this.configuration.blueprint;
    this.conditions = this.configuration.conditions;
    this.filterName = this.configuration.class_name;
    this.conditionsLookup = this.conditions.reduce((lookup, condition) => {
      lookup[condition.id] = condition;
      return lookup;
    }, {});

  }

  conditionConfigFor(conditionId) {
    return this.conditionsLookup[conditionId];
  }

  addGroup() {
    const { blueprint, conditions, addGroup } = this;
    const condition = conditions[0];
    const { meta } = condition;
    const criterion = createCriterion(condition.id, 1, meta);

    if(this.blueprint.length > 0) {
      this.blueprint.push(or());
    }
    this.blueprint.push(criterion);
    blueprintUpdatedEvent(this.blueprint, this.filterName);
  }

  addCriterion(groupId, criterion) {
    this.blueprint[groupId].push(criterion);
    blueprintUpdatedEvent(this.blueprint, this.filterName);
  }

  cleanup() {
    const { blueprint } = this;
    const cleanedBlueprint = [];
    for(let i = 0; i < blueprint.length; i++) {
      const current = blueprint[i];
      const next = blueprint[i + 1];
      if (current.word === 'or') {
        if (next.type !== 'criterion') {
          continue;
        }
      }
      cleanedBlueprint.push(current);
    }
    return cleanedBlueprint;
  }

  delete(conditionId) {
    const { blueprint } = this;
    blueprint.splice(conditionId, 1);
    this.cleanup();
    blueprintUpdatedEvent(this.blueprint, this.filterName);
  }

  updateConditionId(criterionId, conditionId) {
    const criterion = this.blueprint[criterionId];
    if (criterion.type !== 'criterion') {
      throw new Error(`You can't call updateConditionId on a non-criterion type. Trying to update ${JSON.stringify(criterion)}`);
    }
    criterion.condition_id = conditionId;
  }

  replaceInput(criterionId, input) {
    const { blueprint } = this;
    const criterion = blueprint[criterionId];
    criterion.input = input;
    blueprintUpdatedEvent(this.blueprint, this.filterName);
  }

  updateInput(criterionId, input) {
    const { blueprint } = this;
    const criterion = blueprint[criterionId];
    criterion.input = {...criterion.input, ...input};
    blueprintUpdatedEvent(this.blueprint, this.filterName);
  }
}
