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

const blueprintUpdatedEvent = (blueprint, filterName) => {
  const event = new CustomEvent("blueprint-updated", {
    detail: {
      blueprint: JSON.parse(JSON.stringify(blueprint)),
      filterName,
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
    this.filterName = this.configuration.class_name;
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
    blueprintUpdatedEvent(this.serverBlueprint(), this.filterName);
  }

  addCriterion(groupId, criterion) {
    this.blueprint[groupId].push(criterion);
    blueprintUpdatedEvent(this.serverBlueprint(), this.filterName);
  }

  // Client uses a different blueprint format than the server.
  // Convert to format server expects
  serverBlueprint() {
    if (this.blueprint.length === 0) {
      return this.blueprint;
    }

    const groups = JSON.parse(JSON.stringify(this.blueprint));
    const firstGroup = groups.shift();
    const newBlueprint = groups.reduce((serverBlueprint, group) => {
      serverBlueprint.push({
        depth: 0,
        type: 'conjunction',
        word: 'or',
      });
      return serverBlueprint.concat(group);
    }, firstGroup);
    return newBlueprint;
  }

  delete(path) {
    const { configuration } = this;
    const lastPathKey = path[path.length - 1];

    let parent = configuration;
    path.slice(0, -1).forEach(key => parent = parent[key]);

    if (Array.isArray(parent)) {
      parent.splice(lastPathKey, 1);
    } else {
      delete parent[lastPathKey];
    }
    blueprintUpdatedEvent(this.serverBlueprint(), this.filterName);
  }

  update(path, value, callback) {
    const { configuration } = this;

    // Update the configuration object given the path and the value
    let updated = configuration;
    path.slice(0, -1).forEach((key) => {
      updated = updated[key];
    });
    updated[path[path.length - 1]] = value;

    blueprintUpdatedEvent(this.serverBlueprint(), this.filterName);

    const configParam = encodeURIComponent(JSON.stringify(configuration));
    const blueprintParam = encodeURIComponent(JSON.stringify(this.serverBlueprint()));
    const filterNameParam = encodeURIComponent(this.filterName);

    if (callback) {
      callback(`${this.urlValue}?filterName=${filterNameParam}&blueprint=${blueprintParam}`);
    }
  }
}
