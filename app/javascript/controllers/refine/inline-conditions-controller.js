import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ['condition', 'category']

  filterConditions(event) {
    const query = event.currentTarget.value.toLowerCase()
    const visibleCategories = new Set()

    // hide / show condition links that match the query and note which
    // categories should be visible
    this.conditionTargets.forEach(conditionNode => {
      const conditionName = conditionNode.innerHTML.toLowerCase()
      if (conditionName.includes(query)) {
        conditionNode.hidden = false
        visibleCategories.add(conditionNode.dataset.category)
      } else {
        conditionNode.hidden = true
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
