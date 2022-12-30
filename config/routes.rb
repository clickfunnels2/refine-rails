Rails.application.routes.draw do
  namespace :hammerstone do
    resource :refine_blueprint, only: [:show, :new, :create]
    namespace :refine do
      resources :stored_filters, only: [:index, :new, :create] do
        post "find", on: :collection
      end
    end
  end
end
