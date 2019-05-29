Nuntius::Engine.routes.draw do

  get 'callbacks/:message_id(/*path)', to: 'callbacks#create', as: :callback
  post 'callbacks/:message_id(/*path)', to: 'callbacks#create'

  resources :messages
  namespace :admin do
    resources :campaigns
    resources :layouts
    resources :lists do
      resources :subscribers, controller: 'lists/subscribers'
    end
    resources :messages
    resources :layouts
    resources :templates
  end
  root to: 'dashboard#show'
end
