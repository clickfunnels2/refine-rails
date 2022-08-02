import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log('Form Controller Connected')
    this.state = this.getStateController()
    this.blueprintInput = this.addHiddenInput('blueprint')
    this.addHiddenInput('filter', this.state.filterName)
    this.addHiddenInput('id_suffix', this.state.idSuffix)
    this.finishUpdate()
  }

  getStateController() {
    let currentElement = this.element

    while(currentElement !== document.body) {
      const controller = this.application.getControllerForElementAndIdentifier(currentElement, 'refine--state')
      if (controller) {
        return controller
      } else {
        currentElement = currentElement.parentNode
      }
    }

    return null
  }

  addHiddenInput(name, initialValue) {
    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = name
    input.value = initialValue || ''
    this.element.appendChild(input)
    return input
  }

  // called on connect
  finishUpdate() {
    this.state.finishUpdate()
  }

  // Call this on submit
  startUpdate() {
    this.blueprintInput.value = JSON.stringify(this.state.blueprint)
    this.state.startUpdate()
  }

  submitForm() {
    this.startUpdate()
    this.element.requestSubmit()
  }
}
