import { identifierForContextKey } from "@stimulus/webpack-helpers"

import AddController from './refine/add-controller'
import DefaultsController from './refine/defaults-controller'
import DeleteController from './refine/delete-controller'
import FormController from './refine/form-controller'
import StateController from './refine/state-controller'
import StoredFilterController from './refine/stored-filter-controller'
import UpdateController from './refine/update-controller'

export const controllerDefinitions = [
  [AddController, 'refine/add-controller.js'],
  [DefaultsController, 'refine/defaults-controller.js'],
  [DeleteController, 'refine/refine/delete-controller.js'],
  [FormController, 'refine/refine/form-controller'],
  [StateController, 'refine/state-controller.js'],
  [StoredFilterController, 'refine/stored-filter-controller.js'],
  [UpdateController, 'refine/update-controller.js']
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
  UpdateController
}