
# Text Condition

The TextCondition is for columns that hold strings. In its basic form it looks like this: 

```ruby
TextCondition.new('name')
```

This condition has an `id` of `name`, is applied against a column of `name`, and has a display value to the end user of "Name".

The TextCondition provides a number of clauses that let your users filter down to records that start with, end with, contain, or are exactly equal to what they're looking for. See below for more detail on each clause.

## Validation
The TextCondition will automatically validate that the user's input is present.

## Clauses

Below you'll see all of the clauses available on the TextCondition.

To read more general information about clauses, head over to the [clauses](/conditions/clauses) page.

### `CLAUSE_EQUALS`
The attribute exactly matches what the user has entered.

### `CLAUSE_DOESNT_EQUAL`
The attribute doesn't match what the user has entered, _or the attribute is null_.

The simplest way to represent "doesn't equal" in SQL would be `attribute != "value"`. This however will not return any records where `attribute` is `null`.

So if your attribute is a nullable column and your users are looking for "Employees where [title] [does not equal] [manager]", we have to add the `or title is null` to accurately represent what the user is looking for.

### `CLAUSE_STARTS_WITH`
The attribute starts with the value the user entered.

### `CLAUSE_DOESNT_START_WITH`
The attribute does not start with the value the user entered.

### `CLAUSE_ENDS_WITH`
The attribute ends with the value the user entered.

### `CLAUSE_DOESNT_END_WITH`
The attribute does not end with the value the user entered.

### `CLAUSE_CONTAINS`
The attribute contains the value the user entered.

### `CLAUSE_DOESNT_CONTAIN`
The attribute doesn't contain the value the user entered, _or is null_. (See `CLAUSE_DOESNT_EQUAL` for reasoning.)

### `CLAUSE_SET`
The attribute is not null and not an empty string (`''`).

### `CLAUSE_NOT_SET`
The attribute is null or is an empty string (`''`).


