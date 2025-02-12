# Complex Relationship definitions for Filter Condition test and Filter Refinement test
class Contact < ActiveRecord::Base
  has_many :applied_tags, class_name: "Contacts::AppliedTag", dependent: :destroy
  has_many :tags, through: :applied_tags

  has_many :orders
  has_many :line_items, through: :orders
  has_many :products, through: :line_items, source: :original_product
  has_many :churned_line_items, -> { where(orders: {service_status: %w[churned canceled]}) }, through: :orders, source: :line_items
  has_many :churned_products, through: :churned_line_items, source: :original_product

  has_one :last_activity, class_name: "Contacts::LastActivity", dependent: :destroy
end

module Contacts
  def self.table_name_prefix
    "contacts_"
  end
end

class Contacts::AppliedTag < ActiveRecord::Base
  belongs_to :contact, touch: true
  belongs_to :tag, class_name: "Tag"
end

class Contacts::Tag < ActiveRecord::Base
  has_many :applied_tags, class_name: "AppliedTag", dependent: :destroy
  has_many :contacts, through: :applied_tags
end

class Contacts::LastActivity < ActiveRecord::Base
  belongs_to :contact, touch: true, optional: true
end


class Order < ActiveRecord::Base
  belongs_to :contact
  has_many :line_items, class_name: "LineItem", dependent: :destroy
end

class Product < ActiveRecord::Base
end

module Orders
  def self.table_name_prefix
    "orders_"
  end
end

class Orders::LineItem < ActiveRecord::Base
  belongs_to :order, class_name: "Order"
  belongs_to :original_product, class_name: "Product"
end
