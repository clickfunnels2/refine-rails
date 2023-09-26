import { Controller } from "@hotwired/stimulus"
import { useClickOutside } from 'stimulus-use'

// simple controller to hide/show the filter modal
export default class extends Controller {
  static targets = ["frame"]

  static values = {
    src: String
  }

  connect() {
    useClickOutside(this)
  }

  show(event) {
    event.preventDefault()
    this.frameTarget.src = this.srcValue;
  }

  hide(event) {
    event?.preventDefault()
    this.frameTarget.innerHTML = "";
  }

  clickOutside(event) {
    this.hide(event)
  }
}
