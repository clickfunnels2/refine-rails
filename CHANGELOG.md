### 2.1.1 (Not yet released)
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