### 2.11.9
  * WIP Feature - Advanced Condition Select: First pass that presents a shoelace modal component. Falls back to normal popup for clause and value selection
  * Removes previous flags for show_modal, fill_modal, show_save, and stack since they are not preserved through the full flow. Instead users should rely on CSS to show/hide as needed
  * Simplifies the icon implementation to only impact the advanced flow 
### 2.11.8
  * Bugfix - fixing an issue where params being passed for fill_modal wouldn't process correctly
### 2.11.6
  * WIP Feature - Adds initial framework to support a Shoelace modal component for condition selection.
### 2.11.5
  * New Feature - Adds the ability to delete OR groupings which merge them as AND conjunctions
  * Inline UI - adds support for stimulus tooltip plugins
  * Inline UI - tweaks to responsive behavior of the toolbar
### 2.11.4
  * Inline UI - Fixing bug with popup edit modals so clicking outside properly closes them
### 2.11.3
  * Inline UI - configurable wrapping settings
### 2.11.2
  * Inline UI - facelift for the styling of the toolbar
### 2.11.1
  * Inline UI - Stretching toolbar to full width and floating save filter control container to the right, adds clear button
### 2.11.0
  * New Feature - Allow icons to be used in condition dropdowns and give configurable control over rendering of the condition item. Note - this only impacts the Inline UI
### 2.10.1
  * Fix - addressed an issue where if no uncategorized conditions existed, an empty optgroup would appear
### 2.10.0
  * New Feature - Recommended Conditions: allows prepending condition list with recommended conditions
  * New Feature - Allow a filter to specify the order of categories with `def category_order`
### 2.9.14
  * Inline UI - tweaking ui for condition limits to better tell user why they cannot add more.
### 2.9.13
  * OptionCondition selection now has a title attribute on each selection in case of overflow. Users can hover over the items to see the full text
### 2.9.12
  * Inline UI - fixed bug with turbo-streams loading a stored filter
### 2.9.11
  * Inline UI - Reordering elements in popup form to flow better
### 2.9.10
  * Inline UI - Improved inline-ui styling from feedback 
### 2.9.9
  * Inline UI - edge case cleanup for conditions with only st and nst clauses allowed
### 2.9.8
  * Inline UI styling cleanup
### 2.9.2
  * Refinements now work with dropdown UI
### 2.9.1
  * Enhance inline option conditions
  * Fix a bug where inline filters were not loading clause-appropriate forms
### 2.9.0
  * Migrated gem to RubyGems.org for hosting and future updates
### 2.8.6
  * Inline filters now display the user-configured list of clauses instead of all possible clauses
### 2.8.5
  * DateCondition now has a validation to ensue a between range date1 is not greater than date2
  * DateCondition human_readable now returns the same messaging as EQUALS or DOESNT_EQUAL when BETWEEN or NOT_BETWEEN respectively when the two dates input are the same date
  * Removed the redundant refine_refine_ from the routes for refine_blueprints. It is now simply refine_blueprints
### 2.8.4
  * clickOutside handler on inline popups no longer block click events when the popup is closed
### 2.8.3
  * Inline filters condition list sorting ignores case
### 2.8.2
  * Truncate long value names to fix a display issue
### 2.8.1
  * Improvements to condition list UI in inline query builder
### 2.8.0
  * Removes the Hammerstone naming convention from codebase
  * Changes default StoredFilter table name to be "refine_stored_filters"
### 2.7.5
  * Allows user to add timezones to human_readable outputs for DateConditions. 
### 2.7.4
  * more fixes for inline interface in iframes
### 2.7.3
  * add turbo-stream-link stimulus controller for iframe support
### 2.7.2
  * Fix for inline criteria forms in iframes
### 2.7.1
  * Inline UI now supports embedding inside forms on the page
### 2.7.0
  * Styling and bugfixes for inline UI
### 2.6.11
  * Further improves localization support by having calendars support spanish and fixing hardcoded strings.
  * Fixes an issue where if clause options dont exist, the filter form would behave erratically
### 2.6.10
  * Adds additional localization support. See yml file for new supported keys
### 2.6.9
  * Allow filters to determine associated model for validations
### 2.6.8
  * Updated class names for the Inline UI views
### 2.6.7
  * Filters should now define a `#model` method which is used to generate a base scope for evaluating stored filters when they are loaded [#124](https://github.com/hammerstonedev/refine-rails/pull/124)
### 2.6.6
  * Inline filters can now emit a `filter-submit-success` event for use in rich front-end apps [#123](https://github.com/hammerstonedev/refine-rails/pull/123)
### 2.6.5
  * Add configuration option `date_gte_uses_bod` to include a whole day in the range when using a >= comparison
  * Fix a bug rendering option conditions when options were defined as a Proc
  * Add error handling for invalid stored filters
### 2.6.4
  * Add `get_query!` method to raise an error on invalid filters
### 2.6.3
  * Add `default_condition_id` attribute to filter classes.
### 2.6.2
  * Add configuration option `option_condition_ordering` to allow apps to specify a custom ordering of OptionCondition options (e.g. alphabetizing)
### 2.6.1
  * Add configuration option `date_lte_uses_eod` to include a whole day in the range when using a <= comparison
  * Fix a bug where option condition selections were being forced to the first value
### 2.6.0
  * Prevent users from adding criteria if values for existing criteria are blank
### 2.5.5
  * Fix a potential issue with updating Option Conditions introduced in 2.5.4
### 2.5.4
  * Fixes a rendering error that occurred with multiple OptionConditions in a single filter 
### 2.5.3
  * Fixes an error when generating human readable display of OptionConditions that use is set / is not set
  * Fix existing error for existing filters that exceed criteria limit

### 2.5.2
  * Bugfix for "and" buttons creating OR groups
### 2.5.1
  * Add criteria limit to filters.  The default is 5 and any filters over the limit will raise `Hammerstone::Refine::Conditions::Errors::CriteriaLimitExceededError` when loaded.
### 2.5.0
  * V2 "filter pill" UI and architecture. Not a breaking change, existing filters still work. This introduces an entire new concept of an inline filter. 
### 2.4.4
  * features
    * Hotfix to allow end user to create custom condition with a left joins
### 2.4.3 
  * features
    * added generator for creating filters
  * bugfix
    * `Clause doesn't equal` and `clause not between` were not implemented for Date with time conditions. PR #98
    * Add in missing has_error classes as specified by Tamik
    * Fix raw_attribute bug for text conditions
  * Clarified the installation documentation
  * Included the StoredFilter class in the gem assuming that the client would override it as
  necessary
  * Default stored filters to false in filter_builder_dropdown
  * Add automatically stabilize to the gem because it is always required 
  * Add the filter pill partial view to the gem (not to docs because CSS is still an issue)
  * Set default stabilizers to be URL Encoded in filter.rb

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
