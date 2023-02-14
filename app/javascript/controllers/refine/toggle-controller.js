import { Controller } from "@hotwired/stimulus"

// simple controller to hide/show the filter modal
export default class extends Controller {
  static targets = ["content"]

  toggle(_event) {
    this.contentTargets.forEach(node => {
      node.toggleAttribute("hidden")
    })
  }
}
