Rails.application.routes.draw do
  mount Refine::Rails::Engine => "/refine"

  root "contacts#index"
end
