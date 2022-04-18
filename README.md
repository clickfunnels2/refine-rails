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
// import { Application } from "@hotwired/stimulus"
import { controllerDefinitions as refineControllers } from "@hammerstone/refine-stimulus"
// window.Stimulus = Application.start()
Stimulus.load(refineControllers)
```

To manually register (or extend or provide your own replacement for) each Stimulus controller:

```js
// import { Application } from "@hotwired/stimulus"
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
3. run `yarn release`

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
