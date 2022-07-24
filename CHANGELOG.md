### 2.0.0 2022-07-24
* enhancements
	* Create app/controllers/concerns/hammerstone_filter.rb that the client can include in their application_controller. This can then be referenced in their controller they want filtered with something like @refine_filter = apply_filter(DevelopersFilter) (If in the developer_controller and want to apply DevelopersFilter)
	Reference in client application_controller.rb include HammerstoneFilter
	* Add the search_filter_controller to the npm package. Note: this is not in the refine folder b/c it's not necessarily required
	* Allow client to use ENV or Rails credentials. Need a better solution here.
	* Add filter_builder_dropdown to ship with the gem so they can just render the partial. In their index view they can simply -> <%= render partial: 'hammerstone/filter_builder_dropdown' %>
	* Add locales
	* Add routes