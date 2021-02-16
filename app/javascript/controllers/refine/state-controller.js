import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    configuration: Object,
    url: String,
  }

  connect() {
    this.configuration = { ...this.configurationValue };
  }

  update(path, value, callback) {
    const { configuration } = this;

    // Update the configuration object given the path and the value
    let updated = configuration;
    path.slice(0, -1).forEach((key) => {
      updated = updated[key];
    });
    updated[path[path.length - 1]] = value;

    // Send back a URL so that update controller can reload the relevant turbo frame
    const configParam = encodeURIComponent(JSON.stringify(configuration));
    callback(`${this.urlValue}?configuration=${configParam}`);
  }
}
