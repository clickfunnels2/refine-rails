Rails.application.routes.draw do
  namespace :hammerstone do
    resource :refine_blueprint, only: [:show, :update, :create]
    namespace :refine do
      resources :stored_filters, only: [:create, :index, :show, :new, :update, :edit] do
        get "editor", on: :collection
      end
    end
  end
end
