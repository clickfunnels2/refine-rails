import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

/*
  attach to a form element to have it submit to a turbo-stream endpoint

  <form action="/contacts" data-controller="refine--turbo-stream-form" data-action="submit->refine--turbo-stream-form#submit">

  Turbo is supposed to handle this natively but we're seeing issues when the form is inside an iframe
*/
export default class extends Controller {
  async submit(event) {
    console.log("turbo form submit")
    event.preventDefault()
    const request = new FetchRequest(
      (this.element.method || "POST"),
      this.element.action,
      {
        responseKind: "turbo-stream",
        body: new FormData(this.element)
      }
    )
    await request.perform()
  }
}
