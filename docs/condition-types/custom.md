# Custom Conditions

We have done our best to provide you with as many conditions as is possible, but there are going to be times where you may need a different kind of condition that we don't supply out of the box. 

Let's say you have an event table that holds analytics data. These events have an type_id such as "viewed" or "clicked" and each event is tied to a specific contact. A common filter might be "find me all contacts that have viewed a product page for product X". In this filter you want to hold one attribute constant (type_id) *and* filter based on product id. This is a perfect use case for a custom condition. 
To clarify - you are trying to build the following filter `Find me all contacts with events where (type_id = "viewed" AND product_page_id=(user selectable))`. 

This is different from the following query which can be built with two Refine "out of the box" option conditions:  `Find me all contact with events where type_id="viewed AND all contacts with events where product_page_id=(user selectable)`


Let's take a look at how we would build this custom condition: 

## Creating the Class

The very first thing you need to do is create a new class that extends the base `Condition` class provided to you by the package. This will give you several helpful methods right off the bat. In this case, we want our view to be an `OptionCondition`, so we'll extend from `OptionCondition` specifically. We'll call our custom condition `EventTypeOptionCondition`.

```ruby
class EventTypeOptionCondition < Refine::Conditions::OptionCondition
  def apply_condition(input, table, _inverse_clause)
    # TODO: Implement `apply_condition` 
  end 
```

## Attributes and Clauses

Most of the time, you will be applying your logic against an attribute on a model which is backed by a column in a database table. Because this is an extremely common use case, we have provided a ` UsesAttributes` module that brings along a few helpful methods.

Another common use case is to have "clauses" for your condition. Clauses are phrases like "is less than", "is greater than", "contains", "does not contain", etc. Most conditions have clauses. To that end, we also provide a `HasClauses` module to make that simpler.

```ruby
class EventTypeOptionCondition < Refine::Conditions::OptionCondition
  def apply_condition(input, table, _inverse_clause)
    # TODO: Implement `apply_condition` 
  end 
  def clauses
    # TODO: Implement `clauses` -> Needs to return an array of clauses
  end
```

To keep the example simple, we'll let the user choose between "Is" and "Is Not" for their clauses. You can optionally not include clauses because this custom condition subclasses from `OptionCondition`, which has clauses. 
```ruby
class EventTypeOptionCondition < Refine::Conditions::OptionCondition
  def apply_condition(input, table, _inverse_clause)
    # TODO: Implement `apply_condition`
  end

  def clauses
    [
      Clause.new(CLAUSE_EQUALS, "is")
        .requires_inputs(["selected"])
      Clause.new(CLAUSE_DOESNT_EQUAL, "is not")
      .requires_inputs(["selected"])
    ]
  end
```
Because we're allowing them to filter by attribute and type, we'll need to allow the developer to pass in the type they want to hold constant. We'll add methods for that. 

```ruby
class EventTypeOptionCondition < Refine::Conditions::OptionCondition
  def apply_condition(input, table, _inverse_clause)
    # TODO: Implement `apply_condition`
  end

  def clauses
    [
      Clause.new(CLAUSE_EQUALS, "is")
        .requires_inputs(["selected"])
      Clause.new(CLAUSE_DOESNT_EQUAL, "is not")
        .requires_inputs(["selected"])
    ]
  end
  
  def with_type(type)
    @type = type
    self
  end
```

## Developer Validations

To ensure that you things are configured correctly, you can add validations to your class. Remember, it's just a Ruby class! Let's validate that the `type` we set is a valid type.

```ruby
class EventTypeOptionCondition < Refine::Conditions::OptionCondition 
  attr_reader :type
  validate :valid_type

  def valid_type
   # The types sent in by the filter must exist in the event_types table
   raise "Invalid type key" if Events::Type.find_by(key: type).nil?
  end
  
  def apply_condition(input, table, _inverse_clause)
    # TODO: Implement `apply_condition`
  end
  # Omitted Methods
end
````

## Applying the User's Input

Now for the fun part: applying the user's input to the query.

Three parameters are passed to the `apply_condition` method, where we do all of our work. The `input` parameter is the user input, the `table` is the Arel table you want to use to build your query and the `_inverse_clause` parameter can be ignored. 

The `input` variable will contain everything that the user has chosen. Because we're reusing the frontend from the Option Condition, we know that `input` will contain a `selected` key.

In this example we have three methods: `apply_condition` (required), `type_node` (helper), and `group` (helper). Each method is commented with a description below. 

```ruby
class EventTypeOptionCondition < Refine::Conditions::OptionCondition 
  attr_reader :type
  validate :valid_type

  # The call to `super` will perform the standard "option condition" apply. In this case the node is `"(`events`.`product_id` = 2)"`
  # We want to AND that query with the node for type at the event table level. 
  # Apply Condition returns something like "((`events`.`product_id` = 2) AND (`events`.`type_id` = 5))" where `type_id` is set by the developer in the condition call and product_id is choosen by the user. Remember, this is a contacts query, so this will roll up to the contacts level. 
  # 
  def apply_condition(input, table, _inverse_clause)
    group(super.and(type_node(table)))
  end
  
  def type_node(table)
    type_id = Events::Type.find_by(key: type, workspace: workspace).id
    table.grouping(table[:type_id].eq(type_id))
  end

  def group(nodes)
    Arel::Nodes::Grouping.new(nodes)
  end
  # Omitted Methods
end
```

This leaves us with the final class: 

```ruby
class Conditions::EventTypeOptionCondition < Refine::Conditions::OptionCondition
  attr_reader :type
  validate :valid_type

  def valid_type
    # The types sent in by the filter must exist in the event_types table
    raise "Invalid type key" if Events::Type.find_by(key: type, workspace: workspace).nil?
  end

  def with_type(type)
    @type = type
    self
  end

  def apply_condition(input, table, _inverse_clause)
    group(super.and(type_node(table)))
  end

  def type_node(table)
    type_id = Events::Type.find_by(key: type, workspace: workspace).id
    table.grouping(table[:type_id].eq(type_id))
  end

  def group(nodes)
    Arel::Nodes::Grouping.new(nodes)
  end
end

```

## Using the Condition

Now that you've built your custom condition you can use it in your contacts filter:

```ruby
# ContactsFilter
Conditions::EventTypeOptionCondition.new("events.product_id")
                                    .with_display("Viewed Product Page")
                                    .with_type("$view")
                                    .with_options(proc { Product.all.pluck(:id, :name).map { |id, name| {id: id.to_s, display: name} } }),


```

Hopefully this example shows you how powerful and flexible custom conditions can be to meet any specific needs you might have.
