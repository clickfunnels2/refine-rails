class Contact < ApplicationRecord
  has_many :contacts_tags, dependent: :destroy
  has_many :tags, through: :contacts_tags
end
