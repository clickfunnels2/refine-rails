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
          filter: this.stateController.filterName,
          blueprint: JSON.stringify(blueprint),
          form_id: this.stateController.formIdValue
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
}
