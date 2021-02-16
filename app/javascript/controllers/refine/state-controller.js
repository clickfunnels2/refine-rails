import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    configuration: Object,
    url: String,
  }

  updateBlueprint(path, value, callback) {
    const newConfiguration = { ...this.configurationValue };
    let updated = newConfiguration;
    path.slice(0, -1).forEach((key) => {
      updated = updated[key];
    });
    updated[path[path.length - 1]] = value;
    const configParam = encodeURIComponent(JSON.stringify(newConfiguration));
    callback(`${this.urlValue}?configuration=${configParam}`);
  }
}
