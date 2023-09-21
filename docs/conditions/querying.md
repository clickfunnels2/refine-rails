
# Querying

It may be obvious, but it's worth stating: the end goal of this package is to generate a SQL query that represents the user's intent. That being the case, at some point we will need to take the data that the user has entered on the frontend and use that to build up a query on the backend.

The Condition's `apply` method is where this finally happens.

The most fundamental concept that underpins the entire Refine Filter Builder is that <em>each condition is responsible for binding itself to the query.</em>

That means that we can let the TextCondition concern itself only with text. The TextCondition can worry about things like finding records where 
- an attribute starts with `[foo]`
- an attribute ends with `[foo]`
- an attribute contains `[foo]` anywhere

while the DateCondition can worry about records where
- an attribute is between `[date 1]` and `[date 2]`
- an attribute is before `[date 1]`
- an attribute is after `[date 1]` 

Every condition is entirely encapsulated, supplying its own method to add the user's data to the query.

To learn more, take a look at the `apply` method of any of the standard conditions.