import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    turboFrame: String
  }

  updateClause(_event) {
    // update the url with the clause param from the form
    const formData = new FormData(this.element)
    const url = new URL(this.urlValue)
    url.searchParams.set("clause", formData.get("clause"))

    // navigate the modal to refresh the form
    window.Turbo.visit(url.toString(), {frame: this.turboFrameValue})
  }
}