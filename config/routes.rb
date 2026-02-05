Rails.application.routes.draw do
  get "profiles/show"

  scope "(:locale)", locale: /en|de|es|fr/ do
    devise_for :users

    # Root path based on authentication
    root "home#index"

    get "home/index"
    get "faq", to: "home#faq", as: :faq
    get "pricing", to: "home#pricing", as: :pricing
    get "features", to: "home#features", as: :features
    get "dashboard", to: "dashboard#index", as: :dashboard
    post "dashboard", to: "dashboard#create", as: :dashboard_index

    resources :prproj_uploads do
      member do
        get :progress
        get :sequences_select
        get :export_unused
        post :batch_analyze
      end
    end

    resource :profile, only: [ :show ]
    # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
