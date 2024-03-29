## How to integrate the refine filter

Refer to the [installation instructions](/docs/installation.md)

## Troubleshooting

### Stimulus package
Depending on how you import Stimulus Controllers and define `application` it may be `Stimulus.load(refineControllers)`

To confirm the Stimulus controllers are loaded, add `window.Stimulus=application` to `controllers/index.js`
Then in the console inspect the stimulus object:
```bash
Stimulus.router.modulesByIdentifier
```
You should see the `refine--....` controllers listed.

### StyleSheets
Instead of importing the plain `index.css`, include the raw tailwind file in your app's tailwind-parsed source css files. Tailwind v3 is required for this.

```css
/* in application.css */
@import '@clickfunnels/refine-stimulus/app/assets/stylesheets/index.tailwind.css';
```

### Errors
You may have to restart your server if you encounter the error: 
```
 NameError (uninitialized constant ApplicationController::Refine
web    | 
web    |   include Refine::FilterApplicationController
```

## Custom configuration
### Define your own apply_filter_method
If you prefer, you can remove it and define your own `apply_filter`.

This is a helper method you can inspect in `Hammerstone::FilterApplicationController`. You probably *do not* want to use this method but want to implement your own. It will return `@refine_filter` which is generated from the stable_id. The `stable_id` comes in from the params when the form is submitted or the URL is directly changed. 

**SIDE NOTE for Pagy/Jumpstart**
```
    apply_filter(ContactsFilter, initial_query: (Contact.sort_by_params(params[:sort], sort_direction))
    @pagy, @contacts = pagy(@refine_filter.get_query)
```

14. Add external styles - currently themify icons (can be overriden - the trash can icon is located in `_criterion.html.erb`) and `daterangepicker`
A quick way to load them is in the `head` section. Also available as an npm package. 

```
<link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/daterangepicker/daterangepicker.css" />
<link rel="stylesheet" href="https://unpkg.com/@icon/themify-icons/themify-icons.css">
```
 

## How it works

The query builder component emits javascript events which give you information about the state of the filter. The filter emits the following events:
- blueprint-updated
- filter-unstable
- filter-stabilized
- filter-invalid
- filter-stored

#### blueprint-updated
This event is emitted when user input has resulted in a change to the blueprint.  Refine uses this event internally and you can use it in your own code to listen for changes and get the latest state of the form.

event.detail includes the following properties:
- blueprint: a Javascript object detailing the user input to the filter form

#### filter-unstable
This event is emitted when the filter is validating and fetching a new URL-encoded stable ID from the server. This event signals that the current stable_id is out of date. The stable_id should not be used until a filter-stabilized event is emitted.

When the round-trip to the server completes a filter-stabilized event is emitted if the filter is valid.  If the filter is not valid a filter-invalid event will be emitted.

event.detail includes the following properties:
- blueprint: a Javascript object detailing the user input to the filter form

#### filter-stabilized

This event is emitted when the filter has been automatically URL encoded and completed the server side calls. At this point it is safe to use the stable_id. The stable_id will look something like `H4sIAPJsT2IAAzWNwQoDIQxE%252F2XOHrpX....` The stable_id allows the user to copy, share, refresh, or otherwise store the URL, but does not save it to the database. This stabilizer is a great way to allow users to not lose all of their progress without having to save every filter to the database. Note: All filters in the CF repo are automatically URL encode stabilized unless you have explicitly set it differently in your filter class.

event.detail includes the following properties:
- stableId: the URL encoded ID that can be used to reconstruct the filter.
- filterName: the class name of the filter this ID is for defined in your ruby code

#### filter-invalid
This event is emitted when Refine has attempted to refresh the stable_id for the filter but was unable to do so because the user input is not valid.

event.detail includes the following properties:
- blueprint: a Javascript object detailing the user input to the filter form
- errors: an array of error messages describing why the filter is not valid

#### filter-stored: This event is emitted when the filter has been saved to the database (i.e. the user clicked "Save Filter").
event.detail includes the following properties
storedFilterId: the primary key of the associated record in the refine_stored_filters_table

## Forcing validations
To force validations, make a POST request to /refine/blueprints with the following JSON payload:
- filter: the ruby class name of the filter
- blueprint: a JSON-stringifed version of the user-input blueprint
- id_suffix: the string appended to DOM-ids used to uniquely identify this filter

The server will respond with a JSON payload that either includes the URL-encoded stable_id (if valid) or a JSON payload or HTML markup that can be used to rerender the form including validation messages

Example:

```js
const response = await fetch('/refine/blueprints', {
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content
  },
  method: "POST",
  body: JSON.stringify({
    filter: 'ContactsFilter',
    blueprint: JSON.stringify(blueprint),
    id_suffix: 'contacts'
  })
})
```

#### Fetching a stable_id from the server
If you need to get a URL-encoded stable_id for a filter without relying on the filter-stabilized event, you can make a PUT request to /refine/update_stable_id with the following JSON payload:
- filter: the ruby class name of the filter
- blueprint: JSON stringified version of the current blueprint

Example:

```js
const response = await fetch(this.updateStableIdUrlValue, {
  method: 'PUT',
  headers: {
    accept: 'application/json',
    'content-type': 'application/json',
    'X-CSRF-Token': token,
  },
  body: JSON.stringify({
    filter: 'ContactsFilter',
    blueprint: JSON.stringify(blueprint),
  })
})
```

If the filter is valid, the server responds 200 OK with the stable_id in the JSON response
If the filter is not valid, the server responds 422 Unprocessable Entity with an errors array in the JSON response

## Customizing Available Stored Filters

By default the list of available stored filters is scoped to the type of the current filter. You can add additional scoping by assigning a Proc to `Refine::Rails.configuration.stored_filter_scope` in an initializer.

```ruby
# config/initializers/refine_rails.rb

Refine::Rails.configuration.stored_filter_scope = ->(scope) { scope.where(workspace_id: current_user.workspace.id) }
```

Custom scoping Proc's should accept a single argument which is the default scope defined by the gem.  It will be executed in the context of the Rails controller so methods like `current_user` and `params` are available.

## Tweaking Date Comparison behavior
You may run into a situation where users can only pick whole days that are being compared to a date column.  In this case, the default less than or equal behavior will compare to the current time on the day selected, which may exclude some records the user intended to include.  To include the entire selected day in the range, you can set the following in an initializer:

## Show timezones in human_readable output for DateConditions
To optionally add the filter's set timezone to the output of `human_readable`, use the hook `with_human_readable_timezone(true)` on your `DateCondition` or `DateWithTimeCondition`. This will append `(UTC)` or whatever the timezone is to the output.

# config/initializers/refine_rails.rb
```ruby
Refine::Rails.date_lte_uses_eod = true
```

## Customizing OptionCondition ordering
You can customize sorting behavior for all OptionConditon options in an initializer:
```ruby
# config/initializers/refine_rails.rb

# always alphabetize option condition lists
Refine::Rails.configuration.option_condition_ordering = ->(options) { options.sort_by { |o| o[:display] } }
```

## Default Condition
Filters can specify which of their conditions will be selected by default when adding new criteria
```ruby
class UserFilter
  self.default_condition_id = "email"
  # ...
end
```

## Local JavaScript Development

There are a couple different methods developers have used.  One is based on `yarn link` and the other based on `yalc`

### Yarn link method

1. In the gem's folder run:

```sh
yarn link
yarn build --watch # leave this running to automatically rebuild when you change a file
```

2.  From your application's folder run:

```sh
yarn link "@clickfunnels/refine-stimulus"
```

3. Restart your asset build server (webpacker/esbuild/etc)

When you're ready to switch back to the published npm package, run:
```sh
yarn unlink "@clickfunnels/refine-stimulus"
```

#### Troubleshooting yarn link
Note that theoretically, any changes you make to the javascript and css assets should be automatically recompiled by `yarn build --watch` and then picked up by your application.  In practice automatic recompilation can be unreliable.  Here are some things to try if the app isn't picking up your changes:

1.  Confirm that the app is indeed not using your latest changes by adding a `console.log` to the connect method of a stimulus controller
2.  Try restarting `yarn build --watch` from the gem directory
3.  Restart your webpacker/esbuild/etc server
4.  Restart your web server
5.  Run `bin/rails assets:clean` from your app's directory and restart servers

If none of the above steps work, try tearing down the package link and setting it up again:
1. Run `yarn link "@clickfunnels-stimulus"` from your app's directory and shut down all servers.
2. Run `yarn unlink` from the gem directory.
3. Redo the steps listed in this section for setting up the linked package
4. Start up your web and asset servers

### Yalc method:

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

yalc link @clickfunnels/refine-stimulus
```

When you make local updates to the package: 

```bash 
# From this repo (refine-rails)
yarn build
yalc push
```

Running `yarn` again from your project's directory will revert back to the published version of the package on npm.

#### Notes if linking with `yarn link` isn't working:
1. Ran `bin/webpack-dev-server`
2. In `berry-refine-demo-clean` delete node modules and re-yarn (just for fun probably not necessary)
3. in `refine-rails` repo follow all yalc steps below -> you should see this message if successful

```
<<<<<<< HEAD
@hammerstone/refine-stimulus@2.4.2 published in store.
Pushing @hammerstone/refine-stimulus@2.4.2 in [path]
Package @hammerstone/refine-stimulus@2.4.2 linked ==> [path]
=======
@clickfunnels/refine-stimulus@2.4.2 published in store.
Pushing @clickfunnels/refine-stimulus@2.4.2 in /Users/colleenschnettler/Documents/Documents/Developer/Hammerstone/berry-refine-demo-clean
Package @clickfunnels/refine-stimulus@2.4.2 linked ==> /Users/colleenschnettler/Documents/Documents/Developer/Hammerstone/berry-refine-demo-clean/node_modules/@clickfunnels/refine-stimulus
>>>>>>> c30f86b (readme updates)
```
4. Restart server 

## Bullet Train Installation
Add ruby gem 
```
gem "refine-rails"
```

Installing the JavaScript package:

```bash
$ yarn add @clickfunnels/refine-stimulus
```

In `app/javascript/controllers/index.js` add

```js
import { controllerDefinitions as refineControllers } from "@clickfunnels/refine-stimulus"
application.load(refineControllers)
```

## Releasing New Versions

- Every release should update the gem and NPM package so version numbers stay in sync.
- Make sure to update the CHANGELOG with a note explaining what the new version does
- Make sure you have the [bump](https://rubygems.org/gems/bump) gems installed locally

### Releasing the Ruby Gem

```sh
bump patch #(or bump minor, major, etc)
gem build
gem push *.gem
rm *.gem
```

### Releasing the NPM Package

1.  Publish the gem with a new version number
2.  run npm version <update_type> (patch | minor | major) OR directly update the version in package.json
3.  run `npm publish`
