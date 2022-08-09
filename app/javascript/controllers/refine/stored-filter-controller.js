import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['blueprintField']

  updateblueprintField(event) {
    if (this.hasblueprintFieldTarget) {
      const { detail } = event
      const { blueprint } = detail
      this.blueprintFieldTarget.value = JSON.stringify(blueprint)
    }
  }
}
