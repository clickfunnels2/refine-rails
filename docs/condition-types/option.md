
# Option Condition

The option condition is used when you want to allow your users to pick between a set of finite options, usually from a select element.

## Basic Usage

```ruby
   OptionCondition.new('branch')
    .with_attribute('branch_id')
    .with_options(
      [{ 
          id: "1", 
          display: "Dallas"
        }, {
          id: "2", 
          display: "Chicago"
        }]
    )
```
This condition has an id of `branch`, is applied against `branch_id` column, and has a display value to the end user of "Branch".

This will allow your users to pick the employees branch from a pre-defined list of options.

## Defining Options

When using the OptionCondition, you must supply it with a list of valid options by calling the `with_options` method. There are a few different values you can pass in.

### Key Value Pairs

The first is a hash of `id` and `display` values: 

```ruby
  OptionCondition.new('branch')
    .with_attribute('branch_id')
    .with_options(
      [{ 
         id: "10", 
         display: "Dallas"
       }, {
         id: "14", 
         display: "Chicago"
      }, {
         id: "21", 
         display: "Atlanta"
      }]
    )
  ```

### Callables (Procs/Lambdas)

You can pass any callable into the `options` method if you'd prefer:

```ruby
      OptionCondition.new("tags.id")
         .with_display("Tags")
         .with_options(proc { Contacts_tags.pluck(:id, :name).map { |id, name| {id: id.to_s, display: name} } }),
```

## Application to the Query

In the example above, you may be wondering where the `10, 14, and 21` came from. Those are the IDs of the particular branches in this example. So when your user chooses 

`[Branch] [is equal to] [Dallas]` 

the resulting SQL will be equivalent to 

`[branch_id] [=] ["10"]`.

By default we use the option's ID as the value we bind into the query, in this case `10`. This works very well in most cases when you're wanting your users to pick between IDs or enums that you don't mind sending to the frontend.

There are times, however, when you may want not want to send the IDs to the frontend, or the value you're binding to the query is a calculated value that may change over time.

Your IDs need to be unique and unchanging, so that the frontend and backend can always tie together, and any stabilized filters continue to work.

In that case, you may add a `_value` key to your option hash:

```ruby
OptionCondition.new('branch')
    .with_attribute('branch_id')
    .with_options(
      [{
         id: "10",
         display: "Dallas"
       }, {
         id: "14",
         display: "Chicago"
       }, {
         id: "21",
         display: "Atlanta",
        _value: 21
       }]
    )
``` 

By doing this, you have now disassociated the `id` from the `_value` that gets bound to the query. You are now free to change the values in the future without breaking any stored filters. 

It's also important to remember that the `_value` key *does not* get sent to the frontend, which might be important for your application. [Any keys that a prefixed with an underscore](/conditions/meta#hiding-data-from-the-frontend) are not sent to the frontend.

The `_value` can also accept a callback, opening the door for some powerful applications. Imagine a scenario where you wanted be able to filter to employees that are in the same branch as the user running the report. A `branch` has many `contacts`. 

```ruby 
OptionCondition.new('branch')
   .with_attribute('branch_id')
   .with_options(
     [{
        id: "10",
        display: "Dallas"
      }, {
        id: "14",
        display: "Chicago"
      }, {
        id: "me",
        display: "My Branch",
        _value: proc {current_user.branch_id}
      }]
   )
```

Now when a user who is in the Dallas branch runs this filter, it will show Dallas people. And when the exact same filter is run by a Chicago employee, it will show Chicago employees. The filter class doesn't automatically have a reference to `current_user`, so you will have to send it in at runtime. 

## The Null Option

The OptionCondition ships with several useful clauses (see below), one of which is `CLAUSE_NOT_SET`, which looks for `nulls`. 

However, in our branch example from above, you can easily envision a user trying to find employees that are "in the Dallas branch or aren't in a branch at all". This would technically be possible by using a combination of `CLAUSE_NOT_SET` and `CLAUSE_EQUALS`, but going that route is much more complicated than it otherwise should be.

To solve for this common use-case, we've added a `with_nil_option` method for you. By passing an ID into the `with_nil_option` method, you're telling the OptionCondition that whenever the user selects that option, we need to look for `nulls`.

Let's continue our example by adding a "No Branch" option: 

```ruby
OptionCondition.new('branch')
   .with_attribute('branch_id')
   .with_nill_option('none')
   .with_options(
      [{
          id: "none",
          display: "No branch"
        },
       {
        id: "10",
        display: "Dallas"
      }, {
        id: "14",
        display: "Chicago"
      }, {
        id: "21",
        display: "Atlanta"
      }]
   )
```

Now when your user chooses `'none'`, the OptionCondition knows that that is the `null` option, and will intelligently query for nulls.

Your user can now build out their desired criteria from earlier very easily:

`[Branch] [is one of] [No Branch, Dallas]`

You can set your null option ID to anything you want, as long as it doesn't conflict with another option's id.

## Validation
The OptionCondition will automatically validate that the user's input is correct. Because it uses the `HasClauses` module, the clause will be validated to ensure it is one that you've allowed.

Additionally, it will look for the presence of a `selected` key in your user's data unless they've chosen the `CLAUSE_SET` or `CLAUSE_NOT_SET` clauses. If it's required to be there, it will be checked to ensure it's an array full of IDs that match the option IDs you've defined.

Even if your user selects one of the clauses that only requires a single value (`CLAUSE_EQUALS` or `CLAUSE_DOESNT_EQUAL`), the `selected` key should still be an array (albeit with a single item).

## Clauses

Below you'll see all of the clauses available on the OptionCondition.

To read more general information about clauses, head over to the [clauses](/conditions/clauses) page.

### `CLAUSE_EQUALS`
The attribute is equal to the value the user chose. 

If the user chose the `nil_option`, the attribute is `null`.

### `CLAUSE_DOESNT_EQUAL`
The attribute is not equal to the value the user chose or is null. 

If the user chose the `nullOption`, the attribute is not `null`.

### `CLAUSE_IN`
The attribute is equal to one of the options that the user chose.

If the user included the `nullOption` in their selection, then the attribute could also be `null`. 

### `CLAUSE_NOT_IN`
The attribute is not equal to one of the options that the user chose or it _is_ `null`.

If the user included the `nullOption` in their selection, then the attribute is not equal to one of the options that the user chose and it _is not_ `null`.


### `CLAUSE_SET`
The attribute is not null.

### `CLAUSE_NOT_SET`
The attribute is null.
