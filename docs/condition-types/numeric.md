# Numeric Condition

The numeric condition is used for filtering on numeric attributes. This can include both integers and floats.

## Basic Usage
```ruby
 NumericCondition.new('age')
```

This condition has an id of `age`, is applied against a column of `age`, and has a display value to the end user of "Age".

By default, the `NumericCondition` only allows integers through the validation process. If you would like to allow floats, you can call `allow_floats`:

```ruby
 NumericCondition.new('age').allow_floats
```

## Validation

The numeric condition uses Ruby's [`numericality](https://guides.rubyonrails.org/active_record_validations.html#numericality) validator under the hood. 

If you have not called `allow_floats`, then the Ruby [`only_integer`] rule is also applied.

## Clauses

Below you'll see all of the clauses available on the NumericCondition.

To read more general information about clauses, head over to the [clauses](ruby/conditions/clauses) page.

### `CLAUSE_EQUALS`
The attribute is equal to the user's input.

### `CLAUSE_DOESNT_EQUAL`
The attribute is not equal to the user's input.

### `CLAUSE_GREATER_THAN`
The attribute is greater than the user's input.

### `CLAUSE_GREATER_THAN_OR_EQUAL_TO`
The attribute is greater than or equal to the user's input.

### `CLAUSE_LESS_THAN`
The attribute is less than the user's input.

### `CLAUSE_LESS_THAN_OR_EQUAL_TO`
The attribute is less than or equal to the user's input.

### `CLAUSE_BETWEEN`
The attribute is between the two values that the user has entered.

### `CLAUSE_SET`
The attribute is not null.

### `CLAUSE_NOT_SET`
The attribute is null.