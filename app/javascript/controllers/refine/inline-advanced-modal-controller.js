import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ['searchBarInput']

  showSearchBar(event) {
    this.searchBarInputTarget.hidden = false
  }

  hideSearchBar(event) {
    this.searchBarInputTarget.hidden = true
  }
  
}
