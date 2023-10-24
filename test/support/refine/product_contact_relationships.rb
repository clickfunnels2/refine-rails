# Relationship definitions for Filter Condition test and Filter Refinement test

class RefineContact < ActiveRecord::Base
  has_many :refine_events
  has_many :refine_products
end

class RefineProduct < ActiveRecord::Base
  has_many :refine_events
  belongs_to :refine_contact
end

class RefineType < ActiveRecord::Base
  has_many :refine_events
end

class RefineEvent < ActiveRecord::Base
  belongs_to :refine_contact
  belongs_to :refine_product
  belongs_to :refine_type
end
