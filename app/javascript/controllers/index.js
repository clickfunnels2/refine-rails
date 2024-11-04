import { identifierForContextKey } from "@hotwired/stimulus-webpack-helpers"

import AddController from './refine/add-controller'
import CriterionFormController from './refine/criterion-form-controller'
import DefaultsController from './refine/defaults-controller'
import DeleteController from './refine/delete-controller'
import FilterPillsController from './refine/filter-pills-controller'
import PopupController from './refine/popup-controller'
import ModalController from './refine/modal-controller'
import SearchFilterController from './refine/search-filter-controller'
import ServerRefreshController from './refine/server-refresh-controller'
import StateController from './refine/state-controller'
import StoredFilterController from './refine/stored-filter-controller'
import SubmitForm from './refine/submit-form-controller'
import ToggleController from './refine/toggle-controller'
import TurboStreamFormController from './refine/turbo-stream-form-controller'
import TurboStreamLinkController from './refine/turbo-stream-link-controller'
import TypeaheadListController from './refine/typeahead-list-controller'
import UpdateController from './refine/update-controller'
import DateController from './refine/date-controller'
import InlineAdvancedModalController from "./refine/inline-advanced-modal-controller"
import TabGroupController from "./fields/shoelace/tab-group-controller"
import InlineAdvancedModalController from "./refine/inline-advanced-modal-controller"

export const controllerDefinitions = [
  [AddController, 'refine/add-controller.js'],
  [CriterionFormController, 'refine/criterion-form-controller.js'],
  [DefaultsController, 'refine/defaults-controller.js'],
  [DeleteController, 'refine/delete-controller.js'],
  [FilterPillsController, 'refine/filter-pills-controller.js'],
  [PopupController, 'refine/popup-controller.js'],
  [ModalController, 'refine/modal-controller.js'],
  [SearchFilterController, 'refine/search-filter-controller.js'],
  [ServerRefreshController, 'refine/server-refresh-controller.js'],
  [StateController, 'refine/state-controller.js'],
  [StoredFilterController, 'refine/stored-filter-controller.js'],
  [SubmitForm, 'refine/submit-form-controller.js'],
  [ToggleController, 'refine/toggle-controller.js'],
  [TurboStreamFormController, 'refine/turbo-stream-form-controller.js'],
  [TurboStreamLinkController, 'refine/turbo-stream-link-controller.js'],
  [TypeaheadListController, './refine/typeahead-list-controller.js'],
  [UpdateController, 'refine/update-controller.js'],
  [DateController, 'refine/date-controller.js'],
  [InlineAdvancedModalController, 'refine/inline-advanced-modal-controller.js'],
  [TabGroupController, 'fields/shoelace/tab-group-controller.js']
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
  CriterionFormController,
  DefaultsController,
  DeleteController,
  FilterPillsController,
  PopupController,
  ModalController,
  SearchFilterController,
  ServerRefreshController,
  StateController,
  StoredFilterController,
  SubmitForm,
  ToggleController,
  TurboStreamFormController,
  TurboStreamLinkController,
  TypeaheadListController,
  UpdateController,
  DateController,
  InlineAdvancedModalController,
  TabGroupController
}
