
# Database Stabilization

Database stabilization is the most straightforward of all the stabilizers, as it simply stores the filter's state in the database.

You need to create a migration to add the table that will hold filter ids and their corresponding state.
If you choose to use this stabilizer, make sure you've published and run the provided migration:

```shell
rails generate migration AddHammerstoneRefineStoredFilters json:state name:string
rails db:migrate
```

This will create a `hammerstone_refine_stored_filters` table in your database. 

The `StoredFilter` needs to be included in your application: 
@TODO Move to gem

```ruby
module Hammerstone::Refine
  class StoredFilter < ApplicationRecord
    validates_presence_of :state
    self.table_name = "hammerstone_refine_stored_filters"

    def refine_filter
      Refine::Rails.configuration.stabilizer_classes[:db].new.from_stable_id(id: id)
    end

    def blueprint
      JSON.parse(state)["blueprint"]
    end
  end
end
```
