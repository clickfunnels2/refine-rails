
# Clauses

In addition to attributes, a basic building block of conditions is "clauses".

The clause is the part of the condition that links the attribute to the data. Let's break that down a bit.

If you have a condition that allows your users to filter based on employee name, then your end users will end up with filters that include criteria like: 

* Name equals "Aaron"
* Name starts with "A"
* Name does not contain "test"

The pattern that you can see here is `[attribute] [clause] [value]`.

@TODO Insert screenshot of frontend with attribute clause and value identified.

In the examples above, the `attribute` is "Name". The values are "Aaron", "A", and "test'. The clauses are the words that link the `attributes` to the `values`: "equals", "starts with", and "does not contain".

## Default Clauses

Every standard condition that uses clauses defines its own set of reasonable defaults for you to use without having to change anything. However, there may be certain conditions where you don't want particular clauses showing up. We've provided a number of methods to make that easier for you.

## Excluding Clauses

If you would like to exclude certain clauses, you can do so by calling the `without_clauses` method. 

```ruby
TextCondition.new('name')
  .without_clauses([
     TextCondition::CLAUSE_SET,
     TextCondition::CLAUSE_NOT_SET
  ])
```

This will prevent the clauses from being sent to the frontend and shown to your end users. This also prevents them from being valid choices on the backend, if your users were to try to sneak them in.

## Including Only Certain Clauses

Instead of _excluding_ clauses, if you'd prefer to strictly _include_ specific clauses, the `only_clauses` method is available to you.

```ruby
TextCondition.new('name')
  .only_clauses([
     TextCondition::CLAUSE_SET,
     TextCondition::CLAUSE_NOT_SET
  ])
```

With the configuration above, your end users would only be able to choose between the two clauses we've explicitly allowed, the `Is Set` and `Is Not Set` clauses.

## Adding Clauses Back 

If you've excluded clauses that you need to later re-add, you can do that with the `withClauses` method.

```ruby
name_condition = TextCondition.new('name')
  .without_clauses([
     TextCondition::CLAUSE_SET,
     TextCondition::CLAUSE_NOT_SET
  ])

# Later on....

name_condition.with_clauses([TextCondition::CLAUSE_SET])
```

You can chain `with_clauses`, `without_clauses`, and `only_clauses` in any order that you want, but whatever you call last takes the highest priority. 

## Constants

Every standard condition uses clauses, which are represented by class level constants to ease development. We keep the string representations of the clauses as compact as possible so that [stabilized filters](/stabilizers/overview) can be as small as possible. 

Any time you need to use a clause, it's recommended that you use the constant:


```ruby
# This is good...
TextCondition::new('name')
  .only_clauses([
      TextCondition::CLAUSE_SET,
      TextCondition::CLAUSE_NOT_SET
  ])

# This is bad...
TextCondition.new('name')
  .only_clauses([
      'st',
      'nst'
  ])
```

## Displays

Every clause has "id" and a "display" attributes. The id is the value that the frontend and backend communicate via, while the display value is the value you can show to your end users.

For example, for the clause `TextCondition::CLAUSE_STARTS_WITH` the id is `'sw'` and the display is `'Starts With'` by default.

In many cases, you may want to have different display values than the ones we've provided for you. You can use the `remap_clause_displays` method to accomplish that.

```ruby
TextCondition.new('name')
  .remap_clause_dislays({
    TextCondition::CLAUSE_STARTS_WITH:'begins with',
    TextCondition::CLAUSE_CONTAINS: 'includes',
  })
```

In some cases, you may want to remap the displays for _every_ instance of a condition. If your application is not in English, then you would want to change all the displays to the language of your application.

You can accomplish this with the static `default_clause_display_map`.
 Not yet implemented


## Custom Clauses

Not yet implemented 

## Clause Validation Rules

Not yet implemented




