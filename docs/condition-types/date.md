
# Date Condition

The DateCondition is used when you need to filter your records based on a date or datetime. 

## Basic Usage

```ruby
  DateCondition.new("created_at", "Created At"),
```

This condition has an `id` of `created_at`, is applied against a column of `created_at`, and has a display value to the end user of "Created At".

> Passing "Created At" as the display here is actually unnecessary, as that would have been the default based on the `id` of `start_date`.

## Attribute Types

Working with dates and times can be a nightmare, but we've simplified that entire process for you.

Although they vary by database, there are a few different types of columns that could be considered "date" columns:

* **Date** - a column that holds only a date without any time e.g. `2020-09-25`
* **Date With Time** - a column that holds a date + time e.g. `2020-09-25 12:55:01`

Of course it matters what type of column your data resides in, so we provide solutions for all three types.

**Important**: Even though some columns contain times, we currently do not support querying based on time, but rather by date only. If your data contains time we will handle it appropriately, but your users cannot request events between certain _times_, only on or between certain _days_.

### Date
For DateCondition, the default column type is set to `date`. This is for when your data is actually stored as a date, without time, in the database. Common examples are due dates, birthdays, start dates, etc. Things where time does not matter.

Because this is the default, the following two conditions are identical:
```php
DateCondition.new('due_date', 'Due Date');
    
DateCondition.new('due_date', 'Due Date')
    .attribute_is_date
```

### Date With Time

When your data contains both a date and a time, you'll need to set the appropriate data type so that the queries execute properly. 

You have two options for setting a condition to datetime. The first is to call the `attribute_is_date_with_time` method on the DateCondition. 

The second option is to use the `DateWithTimeCondition` class directly. 

```ruby
# Set via convenience class 
DateWithTimeCondition.new('created_at')

# Set via method
DateCondition.new('created_at').attribute_is_date_with_time
```

You may prefer the DateWithTimeCondition for readability. Feel free to inspect that class. You'll notice that it simply extends the `DateCondition` class, but sets the `attributeType` to the "date with time" instead of "date".

You may be wondering why we named it the `DateWithTimeCondition` instead of the `DatetimeCondition`?

We feel that that would cause confusion because in most databases there is also a `timestamp` column that holds a "date with time", but not it is not a `datetime` column. 

We don't want to introduce a situation where you have a migration that creates a `timestamp` column and then use a `DatetimeCondition` to filter it. That naming could be misleading. 


## Timezones
The thing that makes working with dates so nightmarish is timezones. Juggling timezones can make anyone crazy.

<div class='flex justify-center mb-4'>
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Current status: timezones. <a href="https://t.co/kBhE3vZzc9">pic.twitter.com/kBhE3vZzc9</a></p>&mdash; Jack Skinner &#39;;-- (@developerjack) <a href="https://twitter.com/developerjack/status/1278505693318770693?ref_src=twsrc%5Etfw">July 2, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
</div>

No, really.

<div class='flex justify-center mb-4'>
<blockquote class="twitter-tweet"><p lang="es" dir="ltr">TIMEZONES <a href="https://t.co/dwNLBruaSU">pic.twitter.com/dwNLBruaSU</a></p>&mdash; Eric L. Barnes (@ericlbarnes) <a href="https://twitter.com/ericlbarnes/status/1291007418437173248?ref_src=twsrc%5Etfw">August 5, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
</div>

We've made this incredibly easy for you. All you need to do is define what timezone your **data** is stored in, and what timezone your **user** exists in.

### Database Timezone: Single

By default, we assume that your data is stored in the UTC (+00:00) timezone. This is generally considered a best practice, but every app is different and you may have perfectly valid reasons to store your times as some other timezone in the database.

If your data is _not_ in UTC, then you'll have to explicitly set the timezone on the condition.

> Psst... If your attribute is a date then you do not need to define a database timezone, as your data has no time! 

In the following example, we'll inform the DateWithTimeCondition that the stored data is in the `America/Chicago` timezone.

```ruby
DateWithTimeCondition.new("clocked_in").with_database_timezone("America/Chicago")
```

Now when the DateWithTimeCondition applies itself to the query, it will adjust for the fact that the data is not stored in UTC.


### User Timezone

We've covered what to do when your data is stored with a specific timezone, but we've not yet considered what your users _actually mean_ when they say, e.g. "March 1st, 2020." 

If a user is in the UTC timezone and ask for records that were created on March 1st, 2020, they literally mean `2020-03-01 00:00:00 UTC - 2020-03-01 23:59:59 UTC`.

Consider however a user in the America/Chicago (UTC-6) timezone. When they request records that were created on "March 1st, 2020", they actually mean "March 1st, 2020 _in my timezone_", which in UTC would be `2020-02-28 18:00:00 UTC - 2020-03-01 17:59:59 UTC`.

Because "March 1st, 2020" means something different to every user depending on where they are in the world, we allow for you to set the user's timezone so that their results are correct.

You can set the timezone explicitly:
```ruby
DateWithTimeCondition.new("created_at").with_user_timezone("America/Chicago")
```

Or you can set a default user timezone anywhere you like, e.g. a service provider.

```ruby
  DateWithTimeCondition.default_user_timezone = current_user.time_zone if current_user
```

By statically setting the default user timezone on the DateCondition class, you no longer have to ever call `with_user_timezone()` anywhere. 

If you set the `default_user_timezone` **and** call `with_user_timezone()`, the latter will take precendence.

How you set your timezone is up to you, but make sure it's a [timezone that Rails supports](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html). 

## Validation

The DateCondition will handle validating the user's input based on the chosen clause. If two dates are required (e.g. for "is between"), then it will verify that both are there.

If your user chooses a relative clause ("more than" or "less than") then the input will be validated to ensure that the first input is an integer and the second input is a direction ("ago" or "from_now").

#TODO COLLEEN
Be sure that you are handling validation errors on your frontend. You can read more about validation in the [Validating Input](/validation) section. 

## Clauses

Below you'll see all of the clauses available on the DateCondition.

To read more general information about clauses, head over to the [clauses](/conditions/clauses) page.

### `CLAUSE_EQUALS`

The attribute is on the same date as the date the user requested.

### `CLAUSE_DOESNT_EQUAL`

The attribute is not on the same date as the date the user requested.

### `CLAUSE_ON_OR_AFTER`

The attribute is on the same date or later than the user's input.

### `CLAUSE_ON_OR_BEFORE`

The attribute is on the same date or earlier than the user's input.

### `CLAUSE_MORE_THAN / CLAUSE_LESS_THAN`

For the more than / less than clauses, the user is given the option to choose a number of days and a direction, either in the future or the past.

Here are some examples of how the resulting condition might read:
- `more than` `3` days `from now`
- `more than` `4` days `ago` 
- `less than` `5` days `from now`
- `less than` `6` days `ago`
 
Since these clauses are based on "now" they are considered to be relative instead of absolute, because the results could change based on which day you run your query.
 
These clauses are really useful for finding things like:
- records created in the last month
- records updated this week
- invoices due in the next week
- todos that are almost due

### `CLAUSE_BETWEEN`

The attribute is between two dates. This condition delegates to Laravel's `whereBetween` method, which in turn delegates to your database driver. The `between` operator in both MySQL and Postgres is *inclusive*. If you use a different database driver, you'll need to confirm inclusivity.  

### `CLAUSE_SET`

The attribute is simply not `null`.

### `CLAUSE_NOT_SET`

The attribute is `null`.
