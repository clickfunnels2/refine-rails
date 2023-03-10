class Contact < ApplicationRecord
  has_many :contacts_tags
  has_many :tags, through: :contacts_tags
end
