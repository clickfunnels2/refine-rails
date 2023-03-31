Rails.application.routes.draw do
  namespace :hammerstone do
    resource :refine_blueprint, only: [:show, :new, :create] do
      get "stored_filters", on: :collection
    end
    namespace :refine do
      resources :stored_filters, only: [:index, :new, :create] do
        post "find", on: :collection
      end
      namespace :inline do
        resources :criteria, except: [:show]
        resources :stored_filters, only: [:index, :new, :create] do
          post "find", on: :collection
        end
      end
    end
  end
end
