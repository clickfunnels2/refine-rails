import { Controller } from "stimulus";

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
  }

  addCriterion(groupId, criterion) {
    this.blueprint[groupId].push(criterion);
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
    // Send back a URL so that update controller can reload the relevant turbo frame
    const configParam = encodeURIComponent(JSON.stringify(configuration));

    // todo: remove. for integration purposes only
    const encodedBlueprint = encodeURIComponent(JSON.stringify({
      filter: 'Scaffolding::CompletelyConcrete::TangibleThingFilter',
      blueprint: this.blueprint,
    }));
    document.getElementById('demo_link').href=`?configuration=${encodedBlueprint}`;

    if (callback) {
      callback(`${this.urlValue}?configuration=${configParam}`);
    }
  }
}
