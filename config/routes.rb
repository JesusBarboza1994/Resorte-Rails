Rails.application.routes.draw do
  root "resortes#index"
  resources :points
  resources :resortes
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  namespace :api do 
    resources :points, only: [:index]
  end
end
