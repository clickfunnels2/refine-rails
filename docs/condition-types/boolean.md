
# Boolean Condition

The boolean condition is for columns that are either true or false. In its basic form, it looks like this: 

```ruby
BooleanCondition.new("is_onboarded").with_display("Onboarded")
```

This condition has an `id` of `is_onboarded`, is applied against a column of `is_onboarded`, and has a display value to the end user of "Onboarded".

> Remember that condition IDs should be unique and should not change. If you want to disassociate the condition's ID from its attribute, you can explicitly call `with_attribute('value')` to set the attribute.

## Nullable Columns

If you have defined your boolean columns as `nullable` in your schema, the `BooleanCondition` can handle those `nulls` in a few different ways. 

In the following example the `has_allergies` column was created as a nullable boolean. In contrast to the `is_onboarded` column, which is definitely going to always be true or false, the `has_allergies` column could reasonably be `null` if we don't yet know if an employee has any food allergies.  

When it comes to `nullable` columns and the BooleanCondition, you have three options:

1. Treat them as `nulls`.
2. Treat them as `true`.
3. Treat them as `false`.

### The Default

By default, the BooleanCondition treats `nulls` as actual `nulls`, but does not allow the user to choose them. We find this is the most conservative default configuration that avoids misrepresenting the data.

As an illustration, the following two conditions are exactly the same: 

```ruby
BooleanCondition.new('has_allergies')
    
BooleanCondition.new('has_allergies')
  .nulls_are_unknown
  .hide_unknowns 
```

### Nulls as Unknown

If you decide that when the column is `null` the user should be able to filter down to just those records, you can turn on `show_unknowns`:

```ruby
BooleanCondition.new('has_allergies')
  .show_unknowns 
```

This will give the user an "Is Set" and "Is Not Set" clauses so that they can filter down to employees that have `has_allergies` set to `null`.

### Nulls as True or False

There are times where you want to treat a `null` value as either `true` or `false`. 

If you wanted to assume that any employees that haven't filled out their allergy status aren't allergic to anything, you can do that by calling `nulls_are_false`.   

```ruby
# Nulls are treated as false, i.e.: they do not have allergies.
BooleanCondition::make('has_allergies')
  .nulls_are_false
```

On the other hand, if you're worried about accidentally causing an allergic reaction, you can treat all employees with unknown allergy statuses as allergic:

```ruby
# Nulls are treated as true, i.e.: they have allergies.
BooleanCondition.new('has_allergies')
  .nulls_are_true
```

There's no "right" way to represent nulls, every app and every attribute are different. So choose whatever suits your needs the best!

## Clauses

### `CLAUSE_TRUE`
The attribute is `true`. Includes `null` if you have called `nulls_are_true`. 

### `CLAUSE_FALSE`
The attribute is `false`. Includes `null` if you have called `nulls_are_false`.

### `CLAUSE_SET`
The attribute is not null.

### `CLAUSE_NOT_SET`
The attribute is null.
