Rails.application.routes.draw do
  resource :session
  resource :library_media_filter, only: :update
  resources :passwords, param: :token

  namespace :admin do
    resource :settings, only: %i[ edit update ]

    resources :libraries do
      resources :scan_runs, only: %i[ create show ]
      resources :books, only: %i[ index show ] do
        get :hardcover_search, to: "hardcover_metadata#search"
        post :hardcover_metadata, to: "hardcover_metadata#apply"
      end
    end

    root "libraries#index"
  end

  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
