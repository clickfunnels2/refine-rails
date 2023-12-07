import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ['listItem', 'category']

  filter(event) {
    const query = event.currentTarget.value.toLowerCase()
    const visibleCategories = new Set()

    // hide / show listItem links that match the query and note which
    // categories should be visible
    this.listItemTargets.forEach(listItemNode => {
      const listItemName = listItemNode.data.listItemValue.toLowerCase()
      if (listItemName.includes(query)) {
        listItemNode.hidden = false
        visibleCategories.add(listItemNode.dataset.category)
      } else {
        listItemNode.hidden = true
      }
    })

    // hide / show category headers that have
    this.categoryTargets.forEach(categoryNode => {
      const categoryName = categoryNode.innerHTML
      if (visibleCategories.has(categoryName)) {
        categoryNode.hidden = false
      } else {
        categoryNode.hidden = true
      }
    })
  }
}
