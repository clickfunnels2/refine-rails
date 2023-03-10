class ContactsTag < ApplicationRecord
  belongs_to :contact
  belongs_to :tag
end
