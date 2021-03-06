import { Controller } from "stimulus";

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

const blueprintUpdatedEvent = (blueprint, filter) => {
  filter = 'Scaffolding::CompletelyConcrete::TangibleThingFilter';
  const event = new CustomEvent("blueprint-updated", {
    detail: {
      blueprint: [ ...blueprint ],
      filter,
    }});
  window.dispatchEvent(event);
};

export default class extends Controller {
  static values = {
    configuration: Object,
    url: String,
  }

  connect() {
    this.configuration = { ...this.configurationValue };
    this.blueprint = this.configuration.blueprint;
    this.conditions = this.configuration.conditions;
    this.conditionsLookup = this.conditions.reduce((lookup, condition) => {
      lookup[condition.id] = condition;
      return lookup;
    }, {});

  }

  conditionConfigFor(conditionId) {
    return this.conditionsLookup[conditionId];
  }

  addGroup(group) {
    this.blueprint.push(group);
    blueprintUpdatedEvent(this.blueprint);
  }

  addCriterion(groupId, criterion) {
    this.blueprint[groupId].push(criterion);
    blueprintUpdatedEvent(this.blueprint);
  }

  update(path, value, callback) {
    const { configuration } = this;

    // Update the configuration object given the path and the value
    let updated = configuration;
    path.slice(0, -1).forEach((key) => {
      updated = updated[key];
    });
    updated[path[path.length - 1]] = value;
    console.log(this.blueprint);

    blueprintUpdatedEvent(this.blueprint);

    const configParam = encodeURIComponent(JSON.stringify(configuration));

    if (callback) {
      callback(`${this.urlValue}?configuration=${configParam}`);
    }
  }
}
