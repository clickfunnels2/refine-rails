import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'


// Base class for controllers that reload form content from the server
export default class extends Controller {
  connect() {
    this.state.finishUpdate()
  }

  get state() {
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

  // Call this on submit
  startUpdate() {
    this.blueprintInput.value = JSON.stringify(this.state.blueprint)
    this.state.startUpdate()
  }

  async refreshFromServer() {
    this.state.startUpdate()
    const request = new FetchRequest(
      "GET",
      this.state.refreshUrlValue,
      {
        responseKind: "turbo-stream",
        query: {
          filter: this.state.filterName,
          blueprint: JSON.stringify(this.state.blueprint),
          form_id: this.state.formIdValue
        }
      }
    )
    await request.perform()
  }

}
