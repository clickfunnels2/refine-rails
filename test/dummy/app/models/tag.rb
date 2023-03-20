class Tag < ApplicationRecord
  has_many :contacts_tags, dependent: :destroy
  has_many :contacts, through: :contacts_tags
end
