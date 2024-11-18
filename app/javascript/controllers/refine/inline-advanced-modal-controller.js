import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ['searchBarInput', 'categoryListItem', 'categoryBlockItem', 'categoryShortcutItem']

  connect() {
    this.observer = new IntersectionObserver(
      this.handleIntersection.bind(this), {
        threshold: 1
      }
    )

    this.categoryBlockItemTargets.forEach(item => this.observer.observe(item))
  }

  disconnect() {
    this.observer.disconnect()
  }

  handleIntersection(entries) {
    entries.forEach(entry => {
      if(entry.isIntersecting) {
        this.highlightCategory(entry.target.dataset.categoryListBlockValue)
      }
    })
  }

  highlightCategory(categoryName) {
    this.categoryShortcutItemTargets.forEach(item => {
      if(item.dataset.inlineAdvancedModalValue === categoryName) {
        item.classList.add('active')
      } else {
        item.classList.remove('active')
      }
    })
  }

  showSearchBar() {
    this.searchBarInputTarget.hidden = false
  }

  hideSearchBar() {
    this.searchBarInputTarget.hidden = true
  }

  findCategoryElementByName(categoryName) {
    // Use the find method to locate the target with the specified attribute value
    return this.categoryListItemTargets.find(item => item.dataset.categoryListItemValue === categoryName)
  }

  scrollToCategory(event) {
    const categoryName = event.target.dataset.inlineAdvancedModalValue
    const categoryElement = this.findCategoryElementByName(categoryName)
    if(categoryElement) {
      categoryElement.scrollIntoView({
        behavior: "smooth",
        block: "start",
        inline: "nearest"
      })
    }
  }
  
}
