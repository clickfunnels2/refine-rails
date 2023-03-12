import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="hello-world"
export default class extends Controller {
  connect() {
    console.log('Hello World!')
  }
}
