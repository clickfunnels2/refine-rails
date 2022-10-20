## How to integrate the refine filter

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

3. `bundle`

4. `yarn`

5. Import the Stimulus Controllers in your application. 
Typically this is in `app/javascript/controllers/index.js`

```javascript
import { controllerDefinitions as refineControllers } from "@hammerstone/refine-stimulus"
application.load(refineControllers)
```

Depending on how you import Stimulus Controllers and define `application` it may be `Stimulus.load(refineControllers)`
## Troubleshooting Stimulus Controllers
To make sure the Stimulus controllers are loaded properly, add `window.Stimulus=application` to `controllers/index.js`
Then in the console inspect the stimulus object: 
```bash 
Stimulus.router.modulesByIdentifier
```
You should see the `refine--....` controllers listed 

6. Add jquery (necessary for our custom select elements)
`yarn add jquery`

```
import jquery from 'jquery'
window.jQuery = jquery
window.$ = jquery
```

7. Implement a Filter class in `app/filters` that inherits from `Hammerstone::Refine::Filter`. Use this class to define the conditions that can be filtered.

Example (Contacts Filter on a Contact Model)

```ruby 
# app/filters/contacts_filter.rb
class ContactsFilter < Hammerstone::Refine::Filter
  include Hammerstone::Refine::Conditions
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
      TextCondition.new("name"),
      DateCondition.new("created_at"),
      DateCondition.new("updated_at"),

    ]
  end
end
```

8. In your application controller, `include Hammerstone::FilterApplicationController` which is a helper class to get you up and running quickly. You can remove it and use your own `apply_filter` method if you want. 

## Troubleshooting: 
If you see this error: 
```
 NameError (uninitialized constant ApplicationController::Hammerstone
web    | 
web    |   include Hammerstone::FilterApplicationController
```

Please restart your server! 


9. In the controller you'd like to filter on, add the `apply_filter` method. For this example we'll use Contacts model and filter. 
`@refine_filter = apply_filter(ContactsFilter)`

This is a helper method you can inspect in `Hammerstone::FilterApplicationController`. You probably *do not* want to use this method but want to implement your own. It will return `@refine_filter` which is generated from the stable_id. The `stable_id` comes in from the params when the form is submitted or the URL is directly changed. 

10. Set the filter stabilized ENV var or credential. 
If using rails credentials: EDITOR="subl --wait" bin/rails credentials:edit --environment development and set NAMESPACE_REFINE_STABILIZERS: 1 

If using .env, application.yml or another gem set NAMESPACE_REFINE_STABILIZERS=1


11. Add the following to your index view to render a button that activates the filter:
```
<%= render partial: 'hammerstone/filter_builder_dropdown' %>
```

12. Add the `reveal` controller to your application if using the `filter_builder_dropdown` partial

`yarn add stimulus-reveal`

```javascript
//index.js
import RevealController from 'stimulus-reveal'

application.register('reveal', RevealController)
```

13. If the gems tailwind styles are being purged with JIT you can add the gem to `tmp/gems` and add this to your tailwing config.  

``` tailwind.config.js
  './tmp/gems/*/app/views/**/*.html.erb',
  './tmp/gems/*/app/helpers/**/*.rb',
  './tmp/gems/*/app/assets/stylesheets/**/*.css',
  './tmp/gems/*/app/javascript/**/*.js',
```

Run the following rake task: 
```
task :add_temp_gems do 
  target = `bundle show refine-rails`.chomp
  if target.present?
    puts "Linking refine-rails to '#{target}'."
    `ln -s #{target} tmp/gems/refine-rails`
  end
end
```

Don't forget to restart the server! 

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
storedFilterId: the primary key of the associated record in the hammerstone_refine_stored_filters_table

## Forcing validations
To force validations, make a POST request to /hammerstone/refine_blueprints with the following JSON payload:
- filter: the ruby class name of the filter
- blueprint: a JSON-stringifed version of the user-input blueprint
- id_suffix: the string appended to DOM-ids used to uniquely identify this filter

The server will respond with a JSON payload that either includes the URL-encoded stable_id (if valid) or a JSON payload or HTML markup that can be used to rerender the form including validation messages

Example:

```js
const response = await fetch('/hammerstone/refine_blueprints', {
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
If you need to get a URL-encoded stable_id for a filter without relying on the filter-stabilized event, you can make a PUT request to /hammerstone/update_stable_id with the following JSON payload:
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

## Customizing the datepicker
By default date filters use [flatpickr](https://flatpickr.js.org/getting-started/).  End users can specify an alterntive datepicker in their application javascript.  Here's an example using the daterangepicker that ships with Bullet Train:

```javascript
import $ from 'jquery' // ensure jquery is loaded before daterangepicker
import 'daterangepicker'
import 'daterangepicker/daterangepicker.css'

window.HammerstoneRefine ||= {}
window.HammerstoneRefine.datePicker = {
  connect: function() {
    $(this.fieldTarget).daterangepicker({
      singleDatePicker: true,
      autoUpdateInput: false,
      minDate: this.futureOnlyValue ? new Date() : false,
      locale: {
        cancelLabel: "Cancel",
        applyLabel: "Apply",
        format: 'MM/DD/YYYY',
      },
      parentEl: $(this.element),
      drops: this.dropsValue ? this.dropsValue : 'down',
    })

    $(this.fieldTarget).on('apply.daterangepicker', (event, picker) => {
      const format =
      $(this.fieldTarget).val(picker.startDate.format('MM/DD/YYYY'))
      $(this.hiddenFieldTarget).val(picker.startDate.format('YYYY-MM-DD'))
      this.hiddenFieldTarget.dispatchEvent(new Event('change', {bubbles: true}))
    })

    this.plugin = $(this.fieldTarget).data('daterangepicker')
  },
  disconnect: function() {
    if (this.plugin === undefined) {
      return
    }

    $(this.fieldTarget).off('apply.daterangepicker')

    // revert to original markup, remove any event listeners
    this.plugin.remove()
  }
}
````

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

yalc link @hammerstone/refine-stimulus
```

When you make local updates to the package: 

```bash 
# From this repo (refine-rails)
yarn build
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

### TODO
- Documentation for stored filters
 
