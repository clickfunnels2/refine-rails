import { identifierForContextKey } from "@hotwired/stimulus-webpack-helpers"

import AddController from './refine/add-controller'
import DefaultsController from './refine/defaults-controller'
import DeleteController from './refine/delete-controller'
import FormController from './refine/form-controller'
import StateController from './refine/state-controller'
import StoredFilterController from './refine/stored-filter-controller'
import UpdateController from './refine/update-controller'
import SearchFilterController from './search-filter-controller'

export const controllerDefinitions = [
  [AddController, 'refine/add-controller.js'],
  [DefaultsController, 'refine/defaults-controller.js'],
  [DeleteController, 'refine/delete-controller.js'],
  [FormController, 'refine/form-controller.js'],
  [StateController, 'refine/state-controller.js'],
  [StoredFilterController, 'refine/stored-filter-controller.js'],
  [UpdateController, 'refine/update-controller.js'],
  [SearchFilterController, 'search-filter-controller.js']
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
  DefaultsController,
  DeleteController,
  FormController,
  StateController,
  StoredFilterController,
  UpdateController, 
  SearchFilterController
}