Rails.application.routes.draw do
  devise_for :users, path: 'admin-console', path_names: {
    sign_in: 'login',
    sign_out: 'logout'
  }, skip: [:registrations]

  # Allow users to edit their profile/password (but not register new accounts)
  as :user do
    get 'admin-console/edit', to: 'users/registrations#edit', as: :edit_user_registration
    put 'admin-console', to: 'users/registrations#update', as: :user_registration
  end
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  # verb "/path", to: "controller#action"

  get "/about", to: "pages#about"
  get "/competences", to: "pages#competences"
  get "/mentions-legales", to: "pages#legal_mentions"
  get "/cookies", to: "pages#cookies"
  get "/protection-des-donnees", to: "pages#data_protection"
  get 'contact', to: 'contacts#new'
  post 'contacts', to: 'contacts#create'
  resources :articles
end


# https://res.cloudinary.com/roshaym/image/upload/f_auto/LI-In-Bug_jisuer?_a=BACAEuEv
# https://res.cloudinary.com/roshaym/image/upload/f_auto/v1/development/LI-In-Bug_jisuer?_a=BACAEuEv
