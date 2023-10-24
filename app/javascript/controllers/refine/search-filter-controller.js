import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static values = {
    submitUrl: String
  }


  search(event) {
    event.preventDefault()
    this.submitFilter()
    document.activeElement.blur()
  }

  async submitFilter() {
    const {blueprint} = this.stateController
    const request = new FetchRequest(
      "POST",
      this.submitUrlValue,
      {
        responseKind: "turbo-stream",
        body: JSON.stringify({
          refine_filters_builder: {
            filter_class: this.stateController.filterName,
            blueprint_json: JSON.stringify(blueprint),
            client_id: this.stateController.clientIdValue
          }
        })
      }
    )
    await request.perform()
  }

  get stateController() {
    return this
      .element
      .querySelector('[data-controller~="refine--state"]')
      .refineStateController
  }

  loadResults({detail: {url}}) {
    console.log("filter submit success")
    if (window.Turbo) {
      window.Turbo.visit(url)
    } else {
      window.location.href = url
    }
  }
}
