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
    console.log("Connecting modal controller")
    useClickOutside(this)
  }

  disconnect() {
  }

  open(event) {
    console.log("Opening modal!!!", this.srcValue)
    event.preventDefault()
    this.frameTarget.src = this.srcValue;
    this.isOpenValue = true
  }

  close(event) {
    if (this.isOpenValue) {
      event?.preventDefault()
      this.frameTarget.innerHTML = "";
      this.isOpenValue = false
    }
  }

  clickOutside(event) {
    this.close(event)
  }


}