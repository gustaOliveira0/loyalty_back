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

      resources :customers, only: [:index, :show, :create, :update, :destroy]
      resources :sales, only: [:index, :show, :create]
      resources :credit_rules
      resources :categories
      resources :products
    end
  end
end
