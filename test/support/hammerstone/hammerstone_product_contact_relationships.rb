# Relationship definitions for Filter Condition test and Filter Refinement test

class HammerstoneContact < ActiveRecord::Base
  has_many :hammerstone_events
  has_many :hammerstone_products
end

class HammerstoneProduct < ActiveRecord::Base
  has_many :hammerstone_events
  belongs_to :hammerstone_contact
end

class HammerstoneType < ActiveRecord::Base
  has_many :hammerstone_events
end

class HammerstoneEvent < ActiveRecord::Base
  belongs_to :hammerstone_contact
  belongs_to :hammerstone_product
  belongs_to :hammerstone_type
end
