Rails.application.routes.draw do
  # Routes for Devise User login/signup pages
  devise_for :users
  
  # Standard routes for Showtimes and Bookings
  resources :showtimes, only: [:index, :show, :new, :create]
  resources :bookings, only: [:create, :show]

  # The home page of your website will show the list of showtimes
  root "showtimes#index"
end