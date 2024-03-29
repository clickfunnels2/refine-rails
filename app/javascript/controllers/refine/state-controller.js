import { Controller } from "@hotwired/stimulus"
import { delegate, abnegate } from 'jquery-events-to-dom-events'
import { blueprintUpdatedEvent } from '../../refine/helpers'
import { isEqual } from 'lodash'

const criterion = (id, depth, condition) => {
  const component = condition?.component
  const meta = condition?.meta || { clauses: [], options: {}}
  const refinements = condition?.refinements || []
  const { clauses, options } = meta
  let selected
  if (component === 'option-condition') {
    selected = options[0] ? [options[0].id] : []
  } else {
    selected = undefined
  }
  // Set newInput based on component

  let newInput = {
    clause: clauses[0]?.id,
    selected: selected,
  }

  // If refinements are present, add to input array
  refinements.forEach((refinement) => {
    const { meta, component } = refinement
    const { clauses, options } = meta
    let selected
    if (component === 'option-condition') {
      selected = options[0] ? [options[0].id] : []
    } else {
      selected = undefined
    }
    newInput[refinement.id] = {
      clause: clauses[0].id,
      selected: selected,
    }
  })

  return {
    depth,
    type: 'criterion',
    condition_id: id,
    input: newInput,
  }
}

const or = function (depth) {
  depth = depth === undefined ? 0 : depth
  return {
    depth,
    type: 'conjunction',
    word: 'or',
  }
}

const and = function (depth) {
  depth = depth === undefined ? 1 : depth
  return {
    depth,
    type: 'conjunction',
    word: 'and',
  }
}
export default class extends Controller {
  static values = {
    blueprint: Array,
    conditions: Array,
    className: String,
    refreshUrl: String,
    clientId: String,
    validateBlueprintUrl: String,
    defaultConditionId: String
  }
  static targets = ['loading']


  connect() {
    // for select2 jquery events and datepicker
    this.element.refineStateController = this
    this.changeDelegate = delegate('change', ['event', 'picker'])
    this.blueprint = this.blueprintValue
    this.conditions = this.conditionsValue
    this.filterName = this.classNameValue
    this.conditionsLookup = this.conditions.reduce((lookup, condition) => {
      lookup[condition.id] = condition
      return lookup
    }, {})
    this.loadingTimeout = null
    blueprintUpdatedEvent(this.element, {blueprint: this.blueprint, formId: this.formIdValue})
  }

  disconnect() {
    abnegate('change', this.changeDelegate)
  }

  startUpdate() {
    if (this.loadingTimeout) {
      window.clearTimeout(this.loadingTimeout)
    }
    // only show the loading overlay if it's taking a long time
    // to render the updates
    this.loadingTimeout = window.setTimeout(() => {
      this.loadingTarget.classList.remove('hidden')
    }, 1000)
  }

  finishUpdate() {
    if (this.loadingTimeout) {
      window.clearTimeout(this.loadingTimeout)
    }
    this.loadingTarget.classList.add('hidden')
  }

  conditionConfigFor(conditionId) {
    return this.conditionsLookup[conditionId]
  }

  addGroup() {
    const { blueprint, conditions } = this
    const condition = ( conditions.find(c => c.id == this.defaultConditionIdValue) || conditions[0] )
    const { meta } = condition

    if (this.blueprint.length > 0) {
      this.blueprint.push(or())
    }
    this.blueprint.push(criterion(condition.id, 1, condition))
    blueprintUpdatedEvent(this.element, {blueprint: this.blueprint, formId: this.formIdValue})
  }

  addCriterion(previousCriterionId) {
    const { blueprint, conditions } = this
    const condition = ( conditions.find(c => c.id == this.defaultConditionIdValue) || conditions[0] )
    const { meta } = condition
    blueprint.splice(previousCriterionId + 1, 0, and(), criterion(condition.id, 1, condition))
    blueprintUpdatedEvent(this.element, {blueprint: this.blueprint, formId: this.formIdValue})
  }

  deleteCriterion(criterionId) {
    /**
       To support 'groups' there is some complicated logic for deleting criterion.

       Imagine this simplified blueprint: [eq, and, sw, or, eq]

       User clicks to delete the last eq. We also have to delete the preceding or
       otherwise we're left with a hanging empty group

       What if the user deletes the sw? We have to clean up the preceding and.

       Imagine another scenario: [eq or sw and ew]
       Now we delete the first eq but this time we need to clean up the or.

       These conditionals cover these cases.
    **/
    const { blueprint } = this
    const previous = blueprint[criterionId - 1]
    const next = blueprint[criterionId + 1]

    const nextIsOr = next && next.word === 'or'
    const previousIsOr = previous && previous.word === 'or'

    const nextIsRightParen = nextIsOr || !next
    const previousIsLeftParen = previousIsOr || !previous

    const isFirstInGroup = previousIsLeftParen && !nextIsRightParen
    const isLastInGroup = previousIsLeftParen && nextIsRightParen
    const isLastCriterion = !previous && !next

    if (isLastCriterion) {
      this.blueprint = []
    } else if (isLastInGroup && previousIsOr) {
      blueprint.splice(criterionId - 1, 2)
    } else if (isLastInGroup && !previous) {
      blueprint.splice(criterionId, 2)
    } else if (isFirstInGroup) {
      blueprint.splice(criterionId, 2)
    } else {
      blueprint.splice(criterionId - 1, 2)
    }

    blueprintUpdatedEvent(this.element, {blueprint: this.blueprint, formId: this.formIdValue})
  }

  /*
    Updates a criterion in the blueprint
    Returns true if an update was actually performed, or false if no-op
  */
  replaceCriterion(criterionId, conditionId, condition) {
    const criterionRow = this.blueprint[criterionId]
    if (criterionRow.type !== 'criterion') {
      throw new Error(
        `You can't call updateConditionId on a non-criterion type. Trying to update ${JSON.stringify(criterion)}`
      )
    }
    const existingCriterion = this.blueprint[criterionId]
    const newCriterion = criterion(conditionId, criterionRow.depth, condition)
    if (isEqual(existingCriterion, newCriterion)) {
      return false
    } else {
      this.blueprint[criterionId] = newCriterion
      blueprintUpdatedEvent(this.element, {blueprint: this.blueprint, formId: this.formIdValue})
      return true
    }
  }

  updateInput(criterionId, input, inputId) {
    // Input id is an array of hash keys that define the path for this input such as ["input", "date_refinement"]
    const { blueprint } = this
    const criterion = blueprint[criterionId]
    inputId = inputId || 'input'
    const blueprintPath = inputId.split(', ')
    // If the inputId contains more than one element, add input at appropriate depth
    if (blueprintPath.length > 1) {
      criterion[blueprintPath[0]][blueprintPath[1]] = { ...criterion[blueprintPath[0]][blueprintPath[1]], ...input }
    } else {
      criterion[inputId] = { ...criterion[inputId], ...input }
    }
    blueprintUpdatedEvent(this.element, {blueprint: this.blueprint, formId: this.formIdValue})
  }

}
