Nuntius::Engine.routes.draw do

  get 'callbacks/:message_id(/*path)', to: 'callbacks#create', as: :callback
  post 'callbacks/:message_id(/*path)', to: 'callbacks#create'

  namespace :admin do
    resources :templates
    resources :messages
  end
  root to: 'admin/templates#index'
end
