class ContactsController < ApplicationController
  def index
    apply_filter(ContactsFilter)
    @contacts = @refine_filter.get_query
  end
end
