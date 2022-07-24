Rails.application.routes.draw do
  namespace :hammerstone do
    resource :refine_blueprint, only: [:show, :update, :create]
    put "update_stable_id", to: "refine_blueprints#update_stable_id"
    namespace :refine do
      resources :stored_filters, only: [:create, :index, :show, :new, :update, :edit] do
        get "editor", on: :collection
      end
    end
  end
end
