# Complex Relationship definitions for Filter Condition test and Filter Refinement test
class Contact < ActiveRecord::Base
  has_many :applied_tags, class_name: "Contacts::AppliedTag", dependent: :destroy
  has_many :tags, through: :applied_tags

  has_many :orders
  has_many :line_items, through: :orders, class_name: "Orders::LineItem"
  has_many :products, through: :line_items, source: :original_product
  has_many :churned_line_items, -> { where(orders: {service_status: %w[churned canceled]}) }, through: :orders, source: :line_items
  has_many :churned_products, through: :churned_line_items, source: :original_product

  has_many :events

  has_one :last_activity, class_name: "Contacts::LastActivity", dependent: :destroy

  belongs_to :custom_attributes, class_name: "Forms::Submission", optional: true
end

module Contacts
  def self.table_name_prefix
    "contacts_"
  end
end

class Contacts::AppliedTag < ActiveRecord::Base
  belongs_to :contact, touch: true
  belongs_to :tag, class_name: "Contacts::Tag"
end

class Contacts::Tag < ActiveRecord::Base
  has_many :applied_tags, class_name: "Contacts::AppliedTag", dependent: :destroy
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

class Event < ActiveRecord::Base
  belongs_to :contact, optional: true
end


module Forms
  def self.table_name_prefix
    "forms_"
  end
end

class Forms::Submission < ActiveRecord::Base
  belongs_to :contact, optional: true

  has_many :answers, class_name: "Forms::Submissions::Answer"
end

module Forms::Submissions
  def self.table_name_prefix
    "forms_submissions_"
  end
end

class Forms::Submissions::Answer < ActiveRecord::Base
  belongs_to :submission, class_name: "Forms::Submission"
  belongs_to :field, class_name: "Forms::Field"
  belongs_to :fields_option, class_name: "Forms::Fields::Option", optional: true
  has_many :selected_options, class_name: "Forms::Submissions::Answers::SelectedOption", dependent: :destroy, foreign_key: :answer_id, inverse_of: :answer
end

module Forms::Submissions::Answers
  def self.table_name_prefix
    "forms_submissions_answers_"
  end
end

class Forms::Submissions::Answers::SelectedOption < ActiveRecord::Base
  belongs_to :answer, class_name: "Forms::Submissions::Answer", inverse_of: :selected_options
  belongs_to :field_option, class_name: "Forms::Fields::Option"
end

module Forms::Fields
  def self.table_name_prefix
    "forms_fields_"
  end
end

class Forms::Field < ActiveRecord::Base
  has_many :answers, class_name: "Forms::Submissions::Answer", foreign_key: :field_id, inverse_of: :field
  has_many :options, class_name: "Forms::Fields::Option", foreign_key: :field_id, inverse_of: :field
end

class Forms::Fields::Option < ActiveRecord::Base
  belongs_to :field, class_name: "Forms::Field"
end


