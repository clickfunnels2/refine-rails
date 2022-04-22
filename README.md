# Refine::Rails
Short description and motivation.

## Usage
How to use my plugin.

## Installation
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

## Integrating in a clean BT clone

## Bullet Train Installation
- Add ruby gem 
```
source "https://yourAPIKey@gem.fury.io/hammerstonedev" do
  gem "refine-rails"
end
```

- Add front end packages via yarn (see yarn instructions) 
### TO FIX 
- Add Hammerstone routes (these should be in the gem) 

### TO FIX
- Add helper file (why isn't this coming through in the gem)?

- Add necessary methods to `application_controller` 
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
  - Add `stored_filter.rb`
  - Render the filter builder partial. `<%= render partial: 'shared/filter_builder_dropdown' %>`
  - Include `_loading.html.erb or an equivalent`
  - `Add filter_builder_dropdown` or appropriate controller to respond to events 
- Add locales files
## Do we want to include the partial?
 
