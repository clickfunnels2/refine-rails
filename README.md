## Adding Refine to a non Bullet Train application 
1. Add the gem
 
```
source "https://yourKey@gem.fury.io/hammerstonedev" do
  gem "refine-rails"
end
```

2. Add the npm package

```bash
$ yarn add @hammerstone/refine-stimulus
```

3. `bundle` `yarn`

4. In the controller you'd like to filter on, add the `apply_filter` method. For this example we'll use Contacts. 
`@refine_filter = apply_filter(ContactsFilter)`

5. Create a `app/filters/contacts_filter.rb` with the following: 

```
class ContactsFilter < Hammerstone::Refine::Filter
  @@default_stabilizer = Hammerstone::Refine::Stabilizers::UrlEncodedStabilizer

  def initial_query
    Contact.all
  end

  def automatically_stabilize?
    true
  end

  def table
    Contact.arel_table
  end

  def conditions
    [
      Hammerstone::Refine::Conditions::TextCondition.new("first_name"),
      Hammerstone::Refine::Conditions::DateCondition.new("created_at"),
      Hammerstone::Refine::Conditions::DateCondition.new("updated_at"),

    ]
  end
end
```

6. In your application controller, `include Hammerstone::FilterApplicationController`

7. Render the filter partial wherever you want! 

```
<div class="flex flex-col">
  <%# Include the this line if you'd like to dump the sql for testing %>
  <%#= @refine_filter&.get_query&.to_sql %>
  <%= render partial: 'hammerstone/filter_builder_dropdown' %>
</div>
```

8. Set the filter stabilized ENV var or credential. If using rails credentials: 
`EDITOR="subl --wait" bin/rails credentials:edit --environment development` and set `NAMESPACE_REFINE_STABILIZERS: 1`
If using .env, application.yml or another gem set `NAMESPACE_REFINE_STABILIZERS=1`

9.  Import the Stimulus Controllers. 

10. Add jquery 
`yarn add jquery`

```
import jquery from 'jquery'
window.jQuery = jquery
window.$ = jquery
```

### Refine::Rails How to Install - BT and legacy 
Short description and motivation.


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


## Local JavaScript Development

From this repo's directory:
We are using `yalc` for local package development.

```bash
# Add yalc if you don't have it 
# From this repo (refine-rails)
yarn global add yalc

# install dependencies
$ yarn

$ yalc publish

```

From the directory of the project including this package:

```bash

yalc add @hammerstone/refine-stimulus
```

When you make local updates to the package: 

```bash 
# From this repo (refine-rails)
yarn 
yalc push
```

Running `yarn` again from your project's directory will revert back to the published version of the package on npm.


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
- Figure out how to handle `ApplicationFilter` class and if we want to ship with an option of sending in initial query 
- Add `stored_filter.rb` (only if using stored filters - best way for users?) 
 
