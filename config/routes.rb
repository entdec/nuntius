Nuntius::Engine.routes.draw do

  get 'callbacks/:message_id(/*path)', to: 'callbacks#create', as: :callback
  post 'callbacks/:message_id(/*path)', to: 'callbacks#create'

  namespace :admin do
    resources :campaigns do
      member do
        get 'publish'
      end
    end
    resources :layouts
    resources :lists do
      resources :subscribers, controller: 'lists/subscribers'
    end
    resources :messages
    resources :templates
  end
  root to: 'admin/templates#index'
end
