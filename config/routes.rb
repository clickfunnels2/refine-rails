Rails.application.routes.draw do
  namespace :hammerstone do
    resource :refine_blueprint, only: [:show, :update, :create]
    namespace :refine do
      resources :stored_filters, only: [:create, :index, :show, :new] do
        get "editor", on: :collection
        post "find", on: :collection
      end
    end
  end
end
