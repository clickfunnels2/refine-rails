import { Controller } from "@hotwired/stimulus"

// simple controller to hide/show the filter modal
export default class extends Controller {
  static targets = ["frame"]

  static values = {
    src: String
  }

  show(_event) {
    this.frameTarget.src = this.srcValue;
  }

  hide(_event) {
    this.frameTarget.innerHTML = "";
  }
}
