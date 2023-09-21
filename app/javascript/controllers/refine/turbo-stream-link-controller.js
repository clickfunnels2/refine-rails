import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js'

/*
  attach to a link element to have it request turbo stream responses

  <a href="/contacts" data-controller="refine--turbo-stream-link" data-action="refine--turbo-stream-link#get">Click me</a>

  Turbo is supposed to handle this natively with data-turbo-stream but we're
  seeing issues using that attribute inside iframes
*/
export default class extends Controller {
  async visit(event) {
    console.log("visiting", this.element.dataset)
    event.preventDefault()
    const request = new FetchRequest(
      (this.element.dataset.turboMethod || "GET"),
      this.element.href,
      {
        responseKind: "turbo-stream",
      }
    )
    await request.perform()
  }
}
