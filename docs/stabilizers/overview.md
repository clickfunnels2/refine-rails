
# Stabilizing Filters

Here we'll go over the process of stabilizing filters so that they can be viewed, reused, or edited at a later time. We use the term "stabilization" because after a filter goes through the stabilization process, you are returned a string or an ID that will always and forever reference a specific filter in a specific state. 

Stabilization is similar to serializing or encoding, in that a filter with a state `$x` will always stabilize to an ID `$y`, and an ID `$y` will always resolve to a filter with state `$x`. It is bi-directional.

## Persisting? Serializing?

Why do we call it stabilizing and not persisting? Persisting implies that the data will be _stored_ somewhere, which is not necessarily true of all of Refine's stabilization drivers. The Database Stabilizer persists the data, but the URL Encoder does not.

Why don't we call it serializing? Serializing usually implies that _all of the data_ is still present in the resulting value. That's not true of all of Refine's stabilization drivers either! The result of the URL Encoder contains all the data, but the Database Stabilizer returns a small pointer to a record in the database.

We landed on the term "stabilization" because it encompasses both concepts.


## Refine Defaults 

By default, the filters are URL Encoded stabilized. This enables us to pass a `stable_id` to your controller and it is used in the `apply_filter` method that is included in the `FilterApplicationController` helper.

## Configure Automatic Stabilization

You'll need to configure your filter for automatic stabilization. In your filter class add: 

```ruby
def automatically_stabilize?
  true
end
```

And add the `default_stabilizer` to your class: 
```ruby
  @@default_stabilizer = Hammerstone::Refine::Stabilizers::UrlEncodedStabilizer
```

## Stabilization - Rehydrating Filters 

You may call `from_stable_id` on a filter at any time. You'll need to pass in the Stabilizer that you want to use.

```ruby
# Rehydrate a filter from a `stable_id`
filter = Stabilizers::UrlEncodedStabilizer.new.from_stable_id(id: params[:stable_id])
```

You can optionally send in an `initial_query` when rehydrating the filter. This is useful if you're using `cancancan` or `pundit` and want to preserve tenancy

```ruby
# Rehydrate a filter from a `stable_id`
filter = Stabilizers::UrlEncodedStabilizer.new.from_stable_id(id: params[:stable_id], initial_query: initial_query)
```


## Getting the query from a stabilized filter

Once you have the filter object, you can call `get_query` on the object to return the query object. 
```ruby

# Rehydrate a filter from a `stable_id`
filter = Stabilizers::UrlEncodedStabilizer.new.from_stable_id(id: params[:stable_id])
# Get the query - returns and Active Record::Relation object 
filter.get_query
```

## Switching stabilizers
If you'd like **some** of your filters to be saved to you `hammerstone_refine_stored_filters` table, you can "translate" from a URLEncoded id to a Database id. You may want to only save filters once the entire model has pass validation for example. Here is what that would look like: 

```ruby
  def save_filter_and_return_id(id:, initial_query: nil)
    # How to use (in controller) -> filter_id = save_filter_and_return_id(id: params[:stable_id], intial_query: scope)
    # This method returns a primary key of the filter in your hammerstone_refine_stored_filters table which you can then add to your model
    filter = Stabilizers::UrlEncodedStabilizer.new.from_stable_id(id: id, initial_query: initial_query)
    Stabilizers::DatabaseStabilizer.new.to_stable_id(filter: filter)
  end
```


## Provided Stabilizers

We have provided 2 stabilizers out of the box for you. Each one does something a little bit different that makes sense in different situations. You can read more about them on their individual pages.

- [Database](/stabilizers/database) - Persists the state to the database.
- [UrlEncoded](/stabilizers/urlencoded) - Encodes the filter's state but doesn't persist it anywhere. Totally self-contained.

## Writing Your Own Stabilizer

All stabilizers must implement the `Stabilizer` interface, which enforces two methods: `from_stable_id` and `to_stable_id`.

As long as your class conforms to that interface, you are free to implement any custom logic that you like.