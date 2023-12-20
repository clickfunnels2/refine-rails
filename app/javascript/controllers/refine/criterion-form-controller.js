import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

/*
  This controller handles criteria forms
  (refine/inline/criteria/new|edit)
*/
export default class extends Controller {
  static values = {
    url: String,
    formId: String
  }

  async refresh(_event) {
    // update the url with params from the form
    const formElement = document.getElementById(this.formIdValue)
    const formData = new FormData(formElement)

    const request = new FetchRequest(
      "GET",
      this.urlValue,
      {
        query: formData,
        responseKind: "turbo-stream"
      }
    )
    const response = await request.perform()
  }



}
