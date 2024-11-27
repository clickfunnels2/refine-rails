import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ['searchBarInput', 'categoryListItem', 'categoryBlockItem', 'categoryShortcutItem', 'scrollContainer']

  connect() {
    this.observer = new IntersectionObserver(
      this.handleIntersection.bind(this), {
        root: this.scrollContainerTarget,
        threshold: 1.0,
        rootMargin: '0px 0px -80% 0px'
      }
    )

    this.bottomObserver = new IntersectionObserver(
      this.handleBottomIntersection.bind(this), {
        root: this.scrollContainerTarget,
        threshold: 1.0
      }
    )

    this.shouldHighlightCategories = true;
    this.handleHighlightTimeout = null;
    this.bottomMarker = document.getElementById('refine--picker-bottom-marker');

    this.categoryListItemTargets.forEach(item => this.observer.observe(item))
    this.bottomObserver.observe(this.bottomMarker)
  }

  disconnect() {
    this.bottomObserver.disconnect()
    this.observer.disconnect()
  }

  handleIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting && entry.target !== this.bottomMarker) {
        if(entry.intersectionRatio == 1) {
          this.highlightCategory(entry.target.dataset.categoryListItemValue)
        }
      }
    })
  }

  handleBottomIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting && entry.target === this.bottomMarker) {
        this.highlightCategory(this.categoryListItemTargets[this.categoryListItemTargets.length - 1].dataset.categoryListItemValue)
      }
    })
  }
    

  highlightCategory(categoryName, force=false) {
    if(this.shouldHighlightCategories || force) {
      this.categoryShortcutItemTargets.forEach(item => {
        if(item.dataset.inlineAdvancedModalValue === categoryName) {
          item.classList.add('active')
        } else {
          item.classList.remove('active')
        }
      })
    }
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

  clearSelection() {
    this.debounceScrollHighlights();
    this.categoryShortcutItemTargets.forEach((item) => {
      item.classList.remove('active')
    })
  }

  clearSearch() {
    if (this.searchBarInputTarget.querySelector("input")) {
      this.searchBarInputTarget.querySelector("input").value = ''
    }
  }

  scrollToCategory(event) {
    const categoryName = event.target.dataset.inlineAdvancedModalValue
    const categoryElement = this.findCategoryElementByName(categoryName)
    this.shouldHighlightCategories = false;
    if(categoryElement) {
      categoryElement.scrollIntoView({
        behavior: "smooth",
        block: "start",
        inline: "nearest"
      })
    }
    setTimeout(() => {
      this.shouldHighlightCategories = true;
      this.highlightCategory(categoryName, true);
    }, 750);
  }

  debounceScrollHighlights() {
    this.shouldHighlightCategories = false;
    clearTimeout(this.handleHighlightTimeout);
    this.handleHighlightTimeout = setTimeout(() => {
      this.shouldHighlightCategories = true;
    }, 1000)
  }
  
}
