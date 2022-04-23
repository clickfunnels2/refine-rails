# Refine::Rails
Short description and motivation.

## Usage
How to use my plugin.

## Installation (if using BT see BulletTrain installation below) 
Add this line to your application's Gemfile:

```ruby
gem "refine-rails"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install refine-rails
```

Installing the JavaScript package:

```bash
$ yarn add @hammerstone/refine-stimulus
```

Also, make sure that your project uses `jquery` and binds it as `window.$`. Required for catching events dispatched by `select2` dropdowns.

Also note that there's currently a bug with esbuild and stimulus 3.0 compatibility.

### Importing and Registering the Stimulus Controllers

Where you normally import your Stimulus controllers, add the following lines:

```js
// import { Application } from "stimulus"
import { controllerDefinitions as refineControllers } from "@hammerstone/refine-stimulus"
// window.Stimulus = Application.start()
Stimulus.load(refineControllers)
```

If loading in Bullet Train,the load command is 
`application.load(refineControllers)`

To manually register (or extend or provide your own replacement for) each Stimulus controller:

```js
// import { Application } from "stimulus"
import {
  AddController,
  DefaultsController,
  DeleteController,
  FormController,
  StateController,
  StoredFilterController,
  UpdateController
} from "@hammerstone/refine-stimulus"
// window.Stimulus = Application.start()
Stimulus.register('refine--add', AddController)
Stimulus.register('refine--defaults', DefaultsController)
Stimulus.register('refine--delete', DeleteController)
Stimulus.register('refine--form', FormController)
Stimulus.register('refine--state', StateController)
Stimulus.register('refine--stored-filter', StoredFilterController)
Stimulus.register('refine--update', UpdateController)
```

## Contributing
Contribution directions go here.

## Local JavaScript Development

From this repo's directory:

```bash
# install dependencies
$ yarn

# prepare for having a symbolic link to this directory
$ yarn link 

# build and update as you work on the javascript
$ yarn build --watch
```

From the directory of the project including this package:

```bash
# create a symbolic link in node_modules/ to this package
yarn link @hammerstone/refine-stimulus
```

Running `yarn` again from your project's directory will revert back to the published version of the package on npm.

Note: Because of a weird behavior in how `yarn link` works, you might have to make sure the project including this package includes a few of this package's dependencies (e.g. lodash, stimulus, etc)

## Release

1. Publish the gem with a new version number
2. Copy the version number in package.json
3. run `yarn build`. This will prepare the different javascript outputs
4. run `yarn pack`. This will create a new `.tgz` file for the new version
5. run `yarn publish <tgz filename> --new-version <version number in package.json>`
6. remove the `*.tgz` file


## Bullet Train Installation
Add ruby gem 
```
source "https://yourAPIKey@gem.fury.io/hammerstonedev" do
  gem "refine-rails"
end
```

Installing the JavaScript package:

```bash
$ yarn add @hammerstone/refine-stimulus
```

In `app/javascript/controllers/index.js` add

```js
import { controllerDefinitions as refineControllers } from "@hammerstone/refine-stimulus"
application.load(refineControllers)
```

### TO FIX 
- Add Hammerstone routes to the routes file (these should be in the gem) 

```
  # Hammerstone routes
  namespace :hammerstone do
    resource :refine_blueprint, only: [:show, :update, :create]
    put "update_stable_id", to: "refine_blueprints#update_stable_id"
    namespace :refine do
      resources :stored_filters, only: [:create, :index, :show, :new, :update, :edit] do
        get "editor", on: :collection
      end
    end
  end
  ```

### TO FIX
- ~Add helper file (why isn't this coming through in the gem)?~

- Add necessary methods to `account/application_controller` *fastest - replace account/application controller with below*

```ruby
class Account::ApplicationController < ApplicationController
  include Account::Controllers::Base

  def ensure_onboarding_is_complete
    # First check that Bullet Train doesn't have any onboarding steps it needs to enforce.
    return false unless super

    # Most onboarding steps you'll add should be skipped if the user is adding a team or accepting an invitation ...
    unless adding_team? || accepting_invitation?
      # So, if you have new onboarding steps to check for an enforce, do that here:
    end

    # Finally, if we've gotten this far, then onboarding appears to be complete!
    true
  end

  def child_filter_class
    # e.g. `Scaffolding::CompletelyConcrete::TangibleThingsFilter`
    self.class.name.gsub(/^Account::/, "").gsub(/Controller$/, "Filter").constantize
  rescue NameError => _
    nil
  end

  def apply_filter(current_scope = nil)
    if child_filter_class.present?
      @stored_filter = nil
      # @stored_filter = Hammerstone::Refine::StoredFilter.find_by(id: stored_filter_id)
      @stable_id = stable_id
      @refine_filter = if stable_id
        Hammerstone::Refine::Stabilizers::UrlEncodedStabilizer.new.from_stable_id(id: stable_id, initial_query: @parent_object.send(@child_collection))
      elsif @stored_filter
        @stored_filter.refine_filter
      else
        # e.g. `Scaffolding::CompletelyConcrete::TangibleThingsFilter`
        child_filter_class.new([], @parent_object.send(@child_collection))
      end
      # e.g. `@tangible_things = @refine_filter.get_query`
      # TODO We should also make it the expectation at a framework level that when we do this, we also update some type
      # of generically named instance variable like @child_collection, except right now that's just a symbol. The idea
      # here is that any other "plugins" or magic behavior like this should compound and play well with each other.
      instance_variable_set(children_instance_variable_name, @refine_filter.get_query)

      # This takes a current scope from tab, etc and merges it in
      instance_variable_set(children_instance_variable_name, children_instance_variable.merge(current_scope)) if current_scope
    end
  end


  def filter_params
    # The filter can come in as a stored_filter_id (database stabilized) or a stable_id (url encoded)
    params.permit(:filter, :stable_id, :blueprint, :conditions, :clauses, :name, :tab, :site_id, :workspace_id, :product_id, :q, :stored_filter_id)
  end

  def stored_filter_id
    filter_params[:stored_filter_id]
  end

  def stable_id
    filter_params[:stable_id]
  end

  
  def children_instance_variable_name
    # e.g. `tangible_things`
    "@" + self.class.name.gsub(/^Account::/, "").gsub(/Controller$/, "").split("::").last.underscore
  end

  def children_instance_variable
    instance_variable_get(children_instance_variable_name)
  end

end
```
- Or individually add these methods to `account/application_controller.rb`
  - `child_filter_class` (extracts the filter class name)
  - `apply_filter` - include stored id if desired (not included for workshop, only stable id)
  - `def filter_params` 
  - `def stable_id`
  - `def children_instance_variable_name`
  - `def children_instance_variable`


- Add `ApplicationFilter` class 
- Handle javascript
  - Add `filter_link_controller` to enable/disable the Apply button 
  - Add `search_filter_controller` (or different controller) to respond to javascript events (force page reload for simplicity at this point) - add back in the stored filter stuff for a BT integration (removed for workshop) 
  - Add `stored_filter.rb` (only if using stored filters) 
  - Render the filter builder partial. `<%= render partial: 'shared/filter_builder_dropdown' %>`
  - Include `_loading.html.erb or an equivalent`
  - `Add filter_builder_dropdown` or appropriate controller to respond to events 
  - Call `apply_filter` from the index action of the controller you want to use 
  - Add the filter in `filters/modelnameplural_filter.rb` and inherit from `ApplicationFilter` 
## TODO move locales files to gem?
- Add locales files 
## Do we want to include the filter_link_controller, filter_builder_partial when releasing to non BT customers?
 
