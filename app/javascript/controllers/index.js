import { identifierForContextKey } from "@hotwired/stimulus-webpack-helpers"

import AddController from './refine/add-controller'
import ConditionFormController from './refine/condition-form-controller'
import DefaultsController from './refine/defaults-controller'
import DeleteController from './refine/delete-controller'
import FilterPillsController from './refine/filter-pills-controller'
import SearchFilterController from './refine/search-filter-controller'
import ServerRefreshController from './refine/server-refresh-controller'
import StateController from './refine/state-controller'
import StoredFilterController from './refine/stored-filter-controller'
import ToggleController from './refine/toggle-controller'
import UpdateController from './refine/update-controller'
import DateController from './refine/date-controller'

export const controllerDefinitions = [
  [AddController, 'refine/add-controller.js'],
  [ConditionFormController, 'refine/condition-form-controller.js'],
  [DefaultsController, 'refine/defaults-controller.js'],
  [DeleteController, 'refine/delete-controller.js'],
  [FilterPillsController, 'refine/filter-pills-controller.js'],
  [SearchFilterController, 'refine/search-filter-controller.js'],
  [ServerRefreshController, 'refine/server-refresh-controller.js'],
  [StateController, 'refine/state-controller.js'],
  [StoredFilterController, 'refine/stored-filter-controller.js'],
  [ToggleController, 'refine/toggle-controller.js'],
  [UpdateController, 'refine/update-controller.js'],
  [DateController, 'refine/date-controller.js']
].map(function(d) {
  const key = d[1]
  const controller = d[0]
  return {
    identifier: identifierForContextKey(key),
    controllerConstructor: controller
  }
})

export {
  AddController,
  ConditionFormController,
  DefaultsController,
  DeleteController,
  FilterPillsController,
  SearchFilterController,
  ServerRefreshController,
  StateController,
  StoredFilterController,
  ToggleController,
  UpdateController,
  DateController
}
