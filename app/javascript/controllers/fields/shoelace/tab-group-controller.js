// to be used with sl-tab-group
import { Controller } from "@hotwired/stimulus"

// This controller is used to handle the tab group component
// @see https://shoelace.style/components/tab-group
// @param keepScrollPosition [Boolean] - If true, the scroll position will be kept when changing tabs
// @usage <div data-controller="shoelace--tab-group" data-shoelace--tab-group-keep-scroll-position-value="true">

export default class extends Controller {
  static values = {
    keepScrollPosition: { type: Boolean, default: false },
  }

  connect() {
    this.currentScrollYPosition = 0
    this.navigateToTab = this.navigateToTab.bind(this)
    this.handleTabShow = this.handleTabShow.bind(this)

    this.navigateToTab()

    document.addEventListener('turbo:load', this.navigateToTab)
    this.element.addEventListener('sl-tab-show', this.handleTabShow)
  }

  disconnect() {
    document.removeEventListener('turbo:load', this.navigateToTab)
    this.element.removeEventListener('sl-tab-show', this.handleTabShow)
  }

  handleTabShow(event) {
    this.setLocationHash(event)

    if (this.keepScrollPositionValue) {
      this.handleTabChange()
    }
  }

  setLocationHash(event) {
    window.location.hash = event.detail.name
  }

  navigateToTab() {
    let hash = window.location.hash.toString()
    if (hash) {
      this.element.show(hash.slice(1))
    } else {
      /*
       * Turbo doesn't currently support hashes on redirects (see https://github.com/hotwired/turbo/issues/825)
       * so we've created a workaround. Pass `redirect_anchor` as a query param, and the component will convert
       * it to a hash and delete the query param. e.g. `some_url?redirect_anchor=store_upsells`
       */
      const params = new URLSearchParams(window.location.search)
      const redirectedHashParam = params.get('redirect_anchor')
      if (redirectedHashParam) {
        params.delete('redirect_anchor')
        let newParams = params.toString()
        window.history.replaceState(
          null,
          '',
          [window.location.pathname, newParams ? `?${newParams}` : '', '#', redirectedHashParam].join('')
        )
      }
    }
  }

  handleTabChange() {
    this.currentScrollYPosition = window.scrollY
  }

  /**
   * Programmatically reveal a sl-tab-panel via action params.
   * @see Shoelace sl-tab-group show() method
   * @see https://shoelace.style/components/tab-group?id=methods
   *
   * @param {Event} event
   * @param {string} event.params.showPanel - the name attribute of the sl-tab-panel to show
   * @example <button type='button' data-action="click->shoelace--tab-group#show"
   *   data-shoelace--tab-group-show-panel-param="mypanelname">
   * @returns {void}
   */
  show(event) {
    const { showPanel } = event.params
    this.element.show(showPanel)
  }
}
