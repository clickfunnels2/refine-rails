class ContactsController < ApplicationController
  def index
    @contacts = Contact.all.limit(10)
  end
end
