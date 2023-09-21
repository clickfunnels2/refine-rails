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
      if (currentElement.matches('[data-controller~="refine--state"]'))
        return this.application.getControllerForElementAndIdentifier(currentElement, 'refine--state')
      else {
        currentElement = currentElement.parentNode
      }
    }

    return null
  }

  async refreshFromServer(options = {}) {
    const { includeErrors } = options
    this.state.startUpdate()
    const request = new FetchRequest(
      "GET",
      this.state.refreshUrlValue,
      {
        responseKind: "turbo-stream",
        query: {
          "refine_filters_builder[filter_class]": this.state.filterName,
          "refine_filters_builder[blueprint_json]": JSON.stringify(this.state.blueprint),
          "refine_filters_builder[client_id]": this.state.clientIdValue,
          include_errors: !!includeErrors
        }
      }
    )
    await request.perform()
  }
}
