# Installation

1. Add the gem to your `Gemfile`:

```
source "https://yourKey@gem.fury.io/hammerstonedev" do
  gem "refine-rails"
end
```

2. Add the npm package: `yarn add @hammerstone/refine-stimulus`

3. Run `bundle` and `yarn`

4. Import the Stimulus Controllers to your application.
Typically this is in `app/javascript/controllers/index.js`

```javascript
import { controllerDefinitions as refineControllers } from "@hammerstone/refine-stimulus"
application.load(refineControllers)
```

5. Import the style sheet in your application. Typically this is in `app/assets/stylesheets/application.css`

```css
import "@hammerstone/refine-stimulus/app/assets/stylesheets/index.css";
```

6. Add jquery (necessary for our custom select elements)
`yarn add jquery`

Add to `index.js` or the appropriate place in your application

```
import jquery from 'jquery'
window.jQuery = jquery
window.$ = jquery
```

7. Generate Filters for your given models and fields.

Example (Contacts Filter on a Contact Model for name and date classes)

```
rails generate filter contact name:text created_at:date id:numeric
```

8. Include the module in your `ApplicationController`: `include Hammerstone::FilterApplicationController`

9. Apply the filter in your `contacts_controller`. `apply_filter` sets `@refine_filter`. `@refine_filter.get_query` returns an object of `ActiveRecordRelation`. This allows you to chain additional scopes if needed.

```ruby
# contacts_controller.rb
  def index
    # Sets refine filter
    apply_filter(ContactsFilter)
    @contacts = @refine_filter.get_query

    # If you're using Pagy your query will look as follows
    # apply_filter(ContactsFilter, initial_query: (Contact.sort_by_params(params[:sort], sort_direction)))
    # @pagy, @contacts = pagy(@refine_filter.get_query)
    # Uncomment to authorize with Pundit
    # authorize @contacts
  end
```

10. Add the following to your view to render a button that activates the filter. In the example above it would be in `contacts/index`.

`<%= render partial: 'hammerstone/filter_builder_dropdown' %>`

 You should see a working filter - something like [this loom](https://www.loom.com/share/ca1cc42740274ceabe0b7cc908fe1aba).

Celebrate!

## Debugging your queries

You can add this snippet to the same view using the filter to see the query being generated.

`<%=@refine_filter&.get_query&.to_sql%>`
