import { Controller } from "@hotwired/stimulus"
import { useClickOutside } from 'stimulus-use'

// simple controller to hide/show the filter modal
export default class extends Controller {
  static targets = ["frame"]

  static values = {
    src: String,
    isOpen: {type: Boolean, default: false}
  }

  connect() {
    useClickOutside(this)
    this.boundHandleKeyUp = this.handleKeyUp.bind(this)
    document.addEventListener("keyup", this.boundHandleKeyUp)
  }

  disconnect() {
    document.removeEventListener("keyup", this.boundHandleKeyUp)
  }

  show(event) {
    event.preventDefault()
    this.frameTarget.src = this.srcValue;
    this.isOpenValue = true
  }

  hide(event) {
    if (this.isOpenValue) {
      event?.preventDefault()
      event?.stopPropagation()
      this.frameTarget.innerHTML = "";
      this.isOpenValue = false
    }
  }

  clickOutside(event) {
    this.hide(event)
  }

  handleKeyUp(event) {
    if (event.key === "Escape" || event.key === "Esc") {
      this.hide(event)
    }
  }
}
