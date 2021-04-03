import { Controller } from "stimulus";
import { delegate, abnegate } from 'jquery-events-to-dom-events';

// Polyfill for custom events in IE9-11
// https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent#polyfill
(function () {

  if ( typeof window.CustomEvent === "function" ) return false;

  function CustomEvent ( event, params ) {
    params = params || { bubbles: false, cancelable: false, detail: undefined };
    var evt = document.createEvent('CustomEvent');
    evt.initCustomEvent( event, params.bubbles, params.cancelable, params.detail );
    return evt;
  }

  CustomEvent.prototype = window.Event.prototype;

  window.CustomEvent = CustomEvent;

  // eslint expects a return here
  return true;
})();

const criterion = (id, depth, meta) => {
  return {
    depth,
    type: 'criterion',
    condition_id: id,
    input: { clause: meta.clauses[0].id },
  };
};

const or = function(depth) {
  depth = depth === undefined ? 0 : depth;
  return {
    depth,
    type: 'conjunction',
    word: 'or',
  };
};

const and = function(depth) {
  depth = depth === undefined ? 1 : depth;
  return {
    depth,
    type: 'conjunction',
    word: 'and',
  };
};

const blueprintUpdatedEvent = (blueprint, filterName, initialLoad) => {
  console.log([...blueprint]);
  const event = new CustomEvent('blueprint-updated', {
    detail: {
      blueprint: JSON.parse(JSON.stringify(blueprint)),
      filterName,
      initialLoad,
    }});
  window.dispatchEvent(event);
};

export default class extends Controller {
  static values = {
    configuration: Object,
  };
  static targets = [ 'loading' ];

  connect() {
    // for select2 jquery events and datepicker
    this.changeDelegate = delegate('change', ['event', 'picker']);

    this.configuration = { ...this.configurationValue };
    this.blueprint = this.configuration.blueprint;
    this.conditions = this.configuration.conditions;
    this.filterName = this.configuration.class_name;
    this.conditionsLookup = this.conditions.reduce((lookup, condition) => {
      lookup[condition.id] = condition;
      return lookup;
    }, {});
    this.loadingTimeout = null;

    blueprintUpdatedEvent(this.blueprint, this.filterName, true);
  }

  disconnect() {
    abnegate('change', this.changeDelegate);
  }

  startUpdate() {
    if (this.loadingTimeout) {
      window.clearTimeout(this.loadingTimeout);
    }
    // only show the loading overlay if it's taking a long time
    // to render the updates
    this.loadingTimeout = window.setTimeout(() => {
      document.activeElement.blur();
      this.loadingTarget.classList.remove('hidden');
    }, 500);
  }

  finishUpdate() {
    if (this.loadingTimeout) {
      window.clearTimeout(this.loadingTimeout);
    }
    this.loadingTarget.classList.add('hidden');
  }

  conditionConfigFor(conditionId) {
    return this.conditionsLookup[conditionId];
  }

  addGroup() {
    const { blueprint, conditions } = this;
    const condition = conditions[0];
    const { meta } = condition;

    if(this.blueprint.length > 0) {
      this.blueprint.push(or());
    }
    this.blueprint.push(
      criterion(condition.id, 1, meta)
    );
    blueprintUpdatedEvent(this.blueprint, this.filterName);
  }

  addCriterion(previousCriterionId) {
    const { blueprint, conditions } = this;
    const condition = conditions[0];
    const { meta } = condition;

    blueprint.splice(
      previousCriterionId + 1,
      0,
      and(),
      criterion(condition.id, 1, meta),
    );

    blueprintUpdatedEvent(this.blueprint, this.filterName);
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
    const { blueprint } = this;
    const previous = blueprint[criterionId - 1];
    const next = blueprint[criterionId + 1];

    const nextIsOr = next && next.word === 'or';
    const previousIsOr = previous && previous.word === 'or';

    const nextIsRightParen = nextIsOr || !next;
    const previousIsLeftParen = previousIsOr || !previous;

    const isFirstInGroup = previousIsLeftParen && !nextIsRightParen;
    const isLastInGroup = previousIsLeftParen && nextIsRightParen;
    const isLastCriterion = !previous && !next;

    if (isLastCriterion) {
      this.blueprint = [];

    } else if (isLastInGroup && previousIsOr) {
      blueprint.splice(criterionId - 1, 2);

    } else if (isLastInGroup && !previous) {
      blueprint.splice(criterionId, 2);

    } else if (isFirstInGroup) {
      blueprint.splice(criterionId, 2);

    } else {
      blueprint.splice(criterionId - 1, 2);
    }

    blueprintUpdatedEvent(this.blueprint, this.filterName);
  }

  updateConditionId(criterionId, conditionId) {
    const criterion = this.blueprint[criterionId];
    if (criterion.type !== 'criterion') {
      throw new Error(`You can't call updateConditionId on a non-criterion type. Trying to update ${JSON.stringify(criterion)}`);
    }
    criterion.condition_id = conditionId;
  }

  replaceInput(criterionId, input) {
    const { blueprint } = this;
    const criterion = blueprint[criterionId];
    criterion.input = input;
    blueprintUpdatedEvent(this.blueprint, this.filterName);
  }

  updateInput(criterionId, input) {
    const { blueprint } = this;
    const criterion = blueprint[criterionId];
    criterion.input = {...criterion.input, ...input};
    blueprintUpdatedEvent(this.blueprint, this.filterName);
  }
}
