
# Date With Time Condition

The DateWithTimeCondition is an extension of the [DateCondition](/ruby-docs/date), with the default attribute type set to "date with time". 

Therefore, the following two conditions are equivalent:

```ruby
# Using the Datetime condition.
DateWithTimeCondition.new('published_at');

# Using the Date condition, but setting the attribute to datetime.
DateCondition.new('published_at').attribute_is_date_with_time
````


To see what else is available to you, please read the [DateCondition](/ruby-docs/date) documentation.


