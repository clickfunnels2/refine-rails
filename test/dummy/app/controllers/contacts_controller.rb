class ContactsController < ApplicationController
  def index
    @contacts = Contact.all.limit(10)
    apply_filter(ContactsFilter)
    @contacts = @refine_filter.get_query
  end
end
