import { Controller } from "@hotwired/stimulus"

// simple controller to hide/show the filter modal
export default class extends Controller {
  static targets = ["frame"]

  static values = {
    src: String
  }

  connect() {
    console.log("Hello world!")
  }

  show(_event) {
    console.log("Show me the money!", this.frameTarget, this.srcValue)
    this.frameTarget.src = this.srcValue;
  }

  hide(_event) {
    this.frameTarget.innerHTML = "";
  }
}
