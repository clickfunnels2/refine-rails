# Refinements

Allowing your user to build up the perfect filter row by row is a fundamental aspect of Refine. 

There are times, however, when filtering on a _single_ attribute at a time isn't quite enough.

Imagine that your user wants to find contacts that have: `performed a specific event` `at least 4 times` `in the past year`. 

It's very straightforward to give your users a dropdown of event types to choose from:

```php
OptionCondition::make('events.type')
    ->options(function() {
        return EventTypes::query()->pluck('name', 'type');
    });
```

With this single condition, your users can find contacts that have performed an event. But what they can't do is find users that have performed _that_ event `in the past year`.

If you were to add a date condition that let them filter on the time the event happened, it would lose the `type` specificity. Your users could find contacts that had performed **an event** in the last year, but not an event _of a specific type_ in the last year.

To overcome this limitation, Refine has built-in "refinements" for _every_ type of condition, which allow you to filter down to contacts that have performed _an event of a certain type in the last year_. 

## Refining by Date

To refine a condition by date, all you need to do is call `refineByDate` on your condition.

```php
OptionCondition::make('events.type')
    ->options(/* ... */)
    ->refineByDate(); // [tl! highlight]
```

That's it! Now your user is given the full power of an Option Condition _and_ a Date Condition, on the same line, operating against the same data.

> Refinements only work on attributes that are attached to relationships! Read more [below](#when-you-can-use-refinements).

@TODO Screenshot

**Everything available on the [Date Condition](/condition-types/date-condition) is available as a refinement**, because the date refinement is using the Date Condition under the hood.

Every clause, every customization, every method is available to you. Let's take a look at how you'd customize the date refinement.

### Changing the Date Refinement Attribute

If you do nothing at all, the date refinement will assume that your date attribute is called `created_at`, and will generate SQL similar to the following:

```sql 
select * from contacts
where
    contacts.id in (
        select events.contact_id from events
        where
            -- Set by the date refinement [tl! ~~]
            created_at between '2020-01-01 00:00:00' and '2020-12-31 23:59:59' -- [tl! ~~]
            -- Set by the option condition [tl! ~~]
            and (type = 'click') -- [tl! ~~]
    )
```

If you want to change `created_at` to a different column, you can just pass a string into the `refineByDate` method:

```php
OptionCondition::make('events.type')
    ->options(/* ... */)
    ->refineByDate('event_happened_at'); // [tl! ~~]
```

Now the query will look at the `event_happend_at` column instead of the `created_at` column.

### Customizing the Date Refinement by Closure

If you want to further customize the refinement, you can pass a closure in and do _anything you want_.

```php
OptionCondition::make('events.type')
    ->options(/* ... */)
    ->refineByDate(function(DateCondition $refinement) {
        $refinement
            ->attribute('event_happened_at')
            ->withoutClauses([
                 DateCondition::CLAUSE_GREATER_THAN_OR_EQUAL,
                 DateCondition::CLAUSE_LESS_THAN_OR_EQUAL,
            ]);
    });
```

You have full power to restrict the clauses, change the attribute type, set timezones, etc.

### Hinting a Custom Date Condition

If you have a standard Date Condition that you use in your app, you may typehint that class and Refine will give that to you instead of Refine's Date Condition.

```php
OptionCondition::make('events.type')
    ->options(/* ... */)
    ->refineByDate(function(AcmeDateCondition $refinement) {
        // $refinement instanceof AcmeDateCondition === true
    });
```

> Your hinted Date Condition will need to extend the base Date Condition, because we are relying on many of those methods.

If you hint nothing you'll get Refine's Date Condition, and if you hint something that doesn't extend Refine's Date Condition, you'll get a configuration exception.

## Refining by Count

Imagine that your user wants to find contacts that have: `performed a specific event` `at least 4 times` `in the past year`.

We've covered how to handle the `in the past year` part (refining by date), but what about the `at least 4 times part`?

That's where refining by count comes in. To refine by count, you only need to call `refineByCount`:

```php
OptionCondition::make('events.type')
    ->options(/* ... */)
    ->refineByCount(); // [tl! ~~]
```

Now your user is given the full power of an Option Condition _and_ a [Numeric Condition](/condition-types/numeric), on the same line, operating against the same data. 

@TODO Screenshot

Refine will now intelligently add grouping to your query and produce SQL similar to the following:   

```sql
select * from contacts
where
    contacts.id in (
        select events.contact_id from events
        where
            -- Added by the Option Condition
            type = 'link'
        -- Intelligent grouping by the Count Refinement [tl! ~~]
        group by -- [tl! ~~]
            events.contact_id -- [tl! ~~]
        having -- [tl! ~~]
            -- Added by the Count Refinement [tl! ~~] 
            count(*) >= 4 -- [tl! ~~]
    )
```

**Everything available on the [Numeric Condition](/condition-types/numeric-condition) is available as a refinement**, because the count refinement is just using the Numeric Condition under the hood.

Every clause, (almost!) every customization, every method is available to you. Let's take a look at how you'd customize the date refinement.

### Customizing the Count Refinement By Closure

If you want to customize your count refinement, you can pass a closure to the `refineByCount` method. This method will receive a `NumericCondition` by default as its first argument.

```php
OptionCondition::make('events.type')
    ->options(/* ... */)
    ->refineByCount(function(NumericCondition $refinement) {
        $refinement->withoutClauses([
             NumericCondition::CLAUSE_GREATER_THAN_OR_EQUAL,
             NumericCondition::CLAUSE_LESS_THAN_OR_EQUAL,
        ]);
    });
```

### Hinting a Custom Numeric Condition

If you have a standard Numeric Condition that you use in your app, you may typehint that class and Refine will give that to you instead of Refine's Numeric Condition.

```php
OptionCondition::make('events.type')
    ->options(/* ... */)
    ->refineByCount(function(AcmeNumericCondition $refinement) {
        // $refinement instanceof AcmeNumericCondition === true
    });
```

> Your hinted Numeric Condition will need to extend the base Numeric Condition, because we are relying on many of those methods.

If you hint nothing you'll get Refine's Date Condition, and if you hint something that doesn't extend Refine's Numeric Condition, you'll get a configuration exception.


### Things You Cannot Customize

There are a few things you cannot change about the count refinement.

The first thing is the attribute against which it is applied. The count refinement will always be applied against `count(*)`. Refine will add the grouping to make sure this is possible.

Additionally, you can't change the fact that `allowFloats` will always be set to `false` in the count refinement. Since you can't have a partial record, we force this to be `false`.

## Using Both Types of Refinement

You are free to use no refinements, one refinement, or both refinements on your conditions.

If your application lines up well with our default values, then adding both types of refinement is as simple as adding two lines to your condition.

```php
OptionCondition::make('events.type')
    ->options(/* ... */)
    ->refineByDate() // [tl! ~~]
    ->refineByCount(); // [tl! ~~]
```

Of course if you need to customize one or the other type of refinement, you're welcome to do so.

## When You Can Use Refinements

Refinements are available for every type of condition, but they do require certain types of _attributes_ to work.

For instance, you wouldn't ever try to find `Contacts` `where name equals 'Aaron'` `at least 1 time`. The attribute `name` is just a single attribute on a model, there is no way to have the name equal Aaron at least once.

**For refinements to work, the attribute you're querying on must be a [relationship attribute](conditions/attributes#relationship-attributes) on one of Laravel's `*Many` relationships.**

Any of the following relationship types will work: 
- `HasMany`
- `HasManyThrough`
- `MorphToMany`
- `BelongsToMany`

Consider a Contact that has many Events:

Contact.php {.filename}
```php
class User extends Model
{
    public function events()
    {
        return $this->hasMany(Event::class);
    }
}
```

In your ContactFilter, you could allow your users to filter on the event type, and refine by date or count:

ContactFilter.php {.filename}       
```php
class ContactFilter extends Filter
{
    public function initialQuery()
    {
        return Contact::query();
    }

    public function conditions()
    {
        return [
            OptionCondition::make('event.type')
                ->options(function() {
                    return EventTypes::query()->pluck('name', 'type');
                })
                ->refineByDate()
                ->refineByCount()
        ];
    }
}
```