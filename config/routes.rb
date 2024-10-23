Rails.application.routes.draw do
  namespace :refine do
    resource :blueprint, only: [:show, :new, :create] do
      get "stored_filters", on: :collection
      get "validate", on: :collection
    end
    resources :stored_filters, only: [:index, :new, :create] do
      post "find", on: :collection
    end
    namespace :inline do
      resources :criteria, except: [:show] do
        post "merge_groups", on: :collection
        post "clear", on: :collection
      end
      resources :stored_filters, only: [:index, :new, :create] do
        post "find", on: :collection
      end
    end
    namespace :advanced_inline do
      resources :criteria, except: [:show] do
        post "merge_groups", on: :collection
        post "clear", on: :collection
      end
      resources :stored_filters, only: [:index, :new, :create] do
        post "find", on: :collection
      end
    end
  end
end
