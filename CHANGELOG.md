### 2.4.2
  * Update the configuration of stabilizer classes

### 2.4.1 
  * Remove loading div from filter_builder_dropdown 
  * Remove dependency on stimulus reveal stimulus controller 


### 2.4.0
  * Refactor of query and  builder object. Breaking change for existing implementations. PR #86

### 2.3.14
  * bugfix
    * Remove constant refresh from text field 
    * Use correct blueprint reference in stored filter controller

### 2.3.13
  * bugfix
    * Setform in refine_blueprintscontroller

### 2.3.12 2023-01-13
* Cleanup
  * Separate stored filter back end (PR #83)
  * Dispatch events on filter update (PR #82)

### 2.3.11 2022-12-6
* Possible breaking change
  * Remove the constant server refresh PR: #81
### 2.3.10 2022-11-22
* bugfix
  * Properly export tailwind and non tailwind css files

### 2.3.9 (npm package: 2.3.9) 2022-11-15
* features
  * Export stylesheet to npm package

### 2.38 2022-11-14
* features
  * Allow scoping of stored filters on save
  * Remove css from partials and provide file
  * Get filter pills to work with remap clause display

### 2.3.7 2022-11-09
* bugfix
  * Scope stored filters properly by type and allow end user to add custom scoping

### 2.3.6 2022-10-21
* feature
  * Change datepicker to flatpickr and allow user to override
* bugfix
  * For negative has many through relationships (i.e give me all contacts that don't have tag 1)add a flag to switch to "give me all contacts not in the set of contacts where tag = 1" to avoid the has many selecting contacts with multiple tags.

### 2.3.5 2022-10-18
* bugfix
  * don't send blank condition id
  * Fix random blurring during filter input
  * Update queries to allow for multiple databases

### 2.3.2 2022-09-26
* bugfix
  * Change buttons to divs so upstream forms aren't submitted

### 2.3.1 2022-09-26
* bugfix
  * Support turbo frame/index view so customers can load `refine_blueprints` directly without stored filters
  * Update locales
### 2.3.0 2022-09-25
* feature
  * Filter pills
* breaking change
  * Assign uuids to filter modals
  * Switch to turbo streams
  * Remove the concept of "idSuffix"
* bugfix
  * Fix timezone issue with date condition

### 2.2.4 2022-09-14
* bug-fix
  * Add a fallback initial query based on the arel table _only to be used for validations_

### 2.2.3 2022-09-12
* Add date picker to the gem. Note - this will override the `fields/date_controller` currently being used in client. Styles should already be imported via client, confirm before merge.
* bug-fix
  * Uncomment out Options Conditions test and fix `set` `not-set` conditions

### 2.2.2 2022-09-07
* bug-fix
  * show both error messages if neither date is filled in when using "betweens"
  * Use turbo streams instead of json in create action https://github.com/hammerstonedev/refine-rails/pull/48
* Add rake task so customer can add gem to `tmp/gems` (must be run by customer) to pick up gem styling
* Use local partial

### 2.2.1 2022-08-30
* bug-fix
  * Allow deletion of single condition to blank filter state

### 2.2.0 2022-08-29
* Load all stored filters when using stored filters view (bug - need to add scoping to filter)
* Remove workspace_record from stored filters. Client will need to override this controller to get custom attributes on stored filters
* bug-fix
  * Add back and save to locales file
* bug-fix
  * Allow for option condition to have no values https://github.com/hammerstonedev/refine-rails/pull/40
* updates
  * All filters can be deleted using the delete button - there is no "default" condition
  * Load the turbo frame with a "Create a filter" button instead of default condition
  * Use @form in `refine_helper` instead of `@refine_filter` for consistency
  * https://github.com/hammerstonedev/refine-rails/pull/41
* updates https://github.com/hammerstonedev/refine-rails/pull/43
  * Add `Filter` button back to `filter_builder_dropdown` partial
  * Rename and add `search-filter-controller` Stimulus controller as a helper to get up and running fast
* updates https://github.com/hammerstonedev/refine-rails/pull/42
  * Use blueprint as source of truth - emit `blueprintStabilized` event as main piece of information coming from Refine
  * Add stimulus controllers for BT integration -> `stabilize-filter-controller` and `search-filter-controller` to get and push stableId. Optional controllers customers can use for quick setup.

### 2.1.0 2022-08-02
* updates
  * Update from Stiumulus 2 to Stimulus 3. All updates are on the javascript/npm package side, this release updates package.json to use the new package on Stimulus 3.

### 2.0.2 2022-07-24
* bug-fix
  * Move the hammerstone filter application controller helper to controllers/hammerstone so it is accessible via client's application controller if desired.

### 2.0.1 2022-07-24
* bug-fix
  * _date_picker.html.erb remove `blur` listener, keep `$change` and add `change` to comply with updated bullet-train_fields npm package.

### 2.0.0 2022-07-24
* enhancements
  * Create app/controllers/concerns/hammerstone_filter.rb that the client can include in their application_controller. This can then be referenced in their controller they want filtered with something like @refine_filter = apply_filter(DevelopersFilter) (If in the developer_controller and want to apply DevelopersFilter)
    Reference in client application_controller.rb include HammerstoneFilter
  * Add the search_filter_controller to the npm package. Note: this is not in the refine folder b/c it's not necessarily required
  * Allow client to use ENV or Rails credentials. Need a better solution here.
  * Add filter_builder_dropdown to ship with the gem so they can just render the partial. In their index view they can simply -> <%= render partial: 'hammerstone/filter_builder_dropdown' %>
  * Add locales
  * Add routes