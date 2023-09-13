import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

/*
  This controller handles criteria forms
  (hammerstone/refine/inline/criteria/new|edit)
*/
export default class extends Controller {
  static values = {
    url: String,
    turboFrame: String,
    method: { type: String, default: "POST" }
  }

  refresh(_event) {
    // update the url with params from the form
    const formData = new FormData(this.element)
    const url = new URL(this.urlValue)

    for (const [name, value] of formData.entries()) {
      console.log(name, value)
      url.searchParams.set(name, value)
    }

    // navigate the modal to refresh the form
    window.Turbo.visit(url.toString(), {frame: this.turboFrameValue})
  }



}
