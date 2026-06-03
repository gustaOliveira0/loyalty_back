Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "/auth/register", to: "auth#register"
      post "/auth/login", to: "auth#login"

      get  "/qrcode", to: "qrcode#show"

      namespace :public do
        post "/customers", to: "customers#create"
        get  "/store/:store_id", to: "customers#store_info"
      end

      get   "/store_settings", to: "store_settings#show"
      put   "/store_settings", to: "store_settings#update"
      patch "/store_settings", to: "store_settings#update"

      resources :customers, only: [:index, :show, :create, :update, :destroy] do
        member do
          get  :statement
          post :redeem
        end
      end
      get "/dashboard", to: "dashboard#show"
      resources :sales, only: [:index, :show, :create]
      resources :credit_rules
      resources :categories
      resources :products
    end
  end
end
