
# Creating a Filter

Creating your first filter is as simple as creating a new class that extends `Hammerstone::Refine::Filter`. When you do that, you'll notice that there are three methods that need to be implemented: `initial_query`, `table`, and `conditions`.

Typically you can put these in a top-level folder called `Filters`.

```files
// torchlight! {lineNumbers: false, classes: "leading-tight"}
app/
    assets/
    controllers/
    filters/
        employees_filter.rb
    helpers/
    models/
    views/
config/    
db/
```

This is what your class would look like before we implement those methods: 

```ruby 
class EmployeesFilter < Hammerstone::Refine::Filter
  
  def table
    # TODO
  end
  
  def initial_query
    # TODO 
  end
  
  def conditions
    # TODO
  end
end
```

## Initial Query

The `initial_query` method is the starting point for every filter. This allows you, as the developer, to add restrictions into the base query that cannot be changed by the end user. In many cases you can simply use an empty model query:

```ruby
def initial_query
  Employee.all
end
```

This works well in many cases, but not all of them. For instance, if you want to scope the entire filter by `company_id`, you can do so in the `initial_query`:

```ruby
def initial_query
  Employee.where(company_id: 5)
end
```

Or maybe you want to add in a scope:

```ruby
def initial_query
  Employee.active
end
```

You're welcome to do anything you want in this method, as long as you return an `ActiveRecord::Relation`.

## Conditions

Conditions are where you define what your users can filter on. If you wanted to let your users filter based on the employee's name, you could add a "name" condition. 

```ruby
def conditions
  [ 
    TextCondition.new('name', 'Name')
  ]
end
```

## Table
The table is simple the name of the arel table backing your model. It's simply `Model.arel_table`

```ruby
def table
  Employee.arel_table
end
```

# TODO add this to the generator

The package comes with many conditions out of the box that you can use to build your perfect filter. To learn more about conditions, jump to the [conditions overview](/conditions/overview) page.
