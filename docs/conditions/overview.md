
# Conditions Overview

Conditions are the fundamental building block of filters. <em>Every filter defines a set of conditions</em> that your users can use to build up their perfect criteria.

Every condition is entirely encapsulated, supplies its own configuration options, its own [validation](validation) logic, and its own method to [apply the user's data to the query](querying).

Imagine you wanted build a filter for Employee records that let your users filter on the employee's name, birthday, and start year. In that case, you would make an Employee **filter**, with **conditions** for name, birthday and start year.   

We can build this hypothetical filter pretty easily:  
```ruby
class EmployeeFilter < Refine::Filter
  def table
    Employee.arel_table
  end
  
  def initial_query
    Employee.all
  end

  def conditions
    [
      TextCondition.new('name'),
      NumericCondition.new('start_year'),
      DateCondition.new('birthday'),
    ]
  end
end

```

With just a few lines of code in this tiny class, you've given your users the power to build totally custom queries that perfectly suite their needs. If HR needed a report of "Employees that started this year and have a birthday in the next 30 days", they could build it themselves without ever reaching out to a developer! 

For your convenience, we provide a number of common conditions out of the box:

- [Boolean](/condition-types/boolean) - filter on boolean attributes.
- [Date](/condition-types/date) - filter on date attributes.
- [Date with Time](/condition-types/date-with-time) - filter on attributes that have a date and time.
- [Numeric](/condition-types/numeric) - filter on a numeric attribute.
- [Option](/condition-types/option) - filter on an attribute given from a defined set of options.
- [Text](/condition-types/text) - filter on a text attribute.
<!-- - [Existence](/condition-types/existence) - filter on the existence or non-existence of a subquery.-->

## Defining a Filter's Conditions

Every Filter class must implement a `conditions` method which returns the array of available conditions. You are welcome to build that array in any way you want, but usually it makes sense to just return an array, as in our example above. 

Each condition in the array must extend the  `Refine::Conditions` class.

### IDs

The first argument passed to the `new` method is always the `ID` of the condition. The `ID` is the unique identifier of an individual condition; **it should never change**. The `ID` is how the frontend and backend and know that they're talking about the same thing. Each ID needs to be unique per filter. 

In the following bit of code, we're making a `TextCondition` that has an `ID` of `name`.

```ruby 
  TextCondition.new('name')
```

In this example the backend is telling the frontend: "hey, there is a text condition called 'name' that you can use." The frontend then says: "ok, for that condition called 'name'...  here is the data the user entered." Everything is linked together via ID.

The ID of the condition does not have to match your database column name, but often times it does. The ID of the condition is totally up to you and is not linked to the rest of your application in any way at all. 

### Pretty Display / Label

In addition to an ID, every condition has a "Label" (or "Display") that's a prettier, human-readable label to be used on the frontend.

By default, we'll take the `id` that you pass in and try to "prettify" it for the end user. We call `humanize(keep_id_suffix:true)` and `titleize` on it. If you don't like this default, you're welcome to pass in a second parameter:

```ruby
TextCondition.new('name', 'Employee Name')
```

In this example, had we not passed in a second parameter the user would be presented with a condition of "Name". This is probably fine, but in our example we've decided that "Employee Name" is more clear, so we override the default. 

The chainable `with_display` method is available to you as well:
```ruby
TextCondition.new('name').with_display('Employee Name')
```

## Extending Standard Conditions

Most of the time it's easiest to extend a standard condition instead of creating a new one from scratch. We have a whole section on [extending standard conditions](/conditions/extending) that covers that in more detail.

