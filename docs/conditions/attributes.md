
# Attributes

Almost all of the standard conditions are applied against attributes, which are usually columns in your database. 

All of the conditions that operate on attributes use a `uses_attributes` module, which exposes an `with_attribute` method that you can use to set the attribute's value to either a column name or a raw expression.

## Setting an Attribute

By default, when you construct a condition that uses attributes, the `attribute` is optimistically set to the same value as the `id`.

For example, this:

```ruby
DateCondition.new('published_at')
```

is exactly the same as:

```ruby
DateCondition.new('published_at').with_attribute('published_at')
```

If you are [storing your filters](/stabilizers/overview), it is vitally important that your condition's `ID` never change. If the `ID` were to change in your code but not in your stored state, we would no longer be able to match the stored data to the condition.

For clarity, you may decide to always explicitly set the attribute using the `attribute` method, even when the ID and attribute match. That is a perfectly reasonable decision!

## Relationship Attributes

There may be times when you want to allow your users to query attributes on _related_ models, instead of the model upon which the filter is based.

We take of this common scenario for you. Normally when you set an attribute, it's understood to be an attribute on the base model. But if you pass and attribute in the form of `{relation}.{attribute}` then we'll handle the subquery required to query the relationship.

In the scenario where your filter is an `Employee` filter, and there is a `Manager` relationship, you can easily allow your users to query on the manager's name by setting your condition up as follows:

```ruby
TextCondition::new('manager_name').with_attribute('manager.name')
```

Every type of Rails relationship is supported and any condition that uses attributes supports querying attributes on related models. Infinitely nested relationships are also supported, although you'll need to weigh the performance considerations of multiple levels of nesting.

The following is totally valid: 

```ruby
TextCondition.new('regional_manager_name').with_attribute('manager.manager.name')
```

   
## JSON Attributes

Not supported at this time

## Raw Expression Attributes

Not supported at this time