import { identifierForContextKey } from "@stimulus/webpack-helpers"

import AddController from './add-controller'
import DefaultsController from './defaults-controller'
import DeleteController from './delete-controller'
import FormController from './form-controller'
import StateController from './state-controller'
import StoredFilterController from './stored-filter-controller'
import UpdateController from './update-controller'

export const controllerDefinitions = [
  [AddController, './add-controller.js'],
  [DefaultsController, './defaults-controller.js'],
  [DeleteController, './delete-controller.js'],
  [FormController, './form-controller.js'],
  [StateController, './state-controller.js'],
  [StoredFilterController, './stored-filter-controller.js'],
  [UpdateController, './update-controller.js']
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
