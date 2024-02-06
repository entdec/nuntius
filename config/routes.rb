# frozen_string_literal: true

Nuntius::Engine.routes.draw do
  namespace :inbound_messages do
    resource :twilio_inbound_smses
  end

  get 'callbacks/:message_id(/*path)', to: 'callbacks#create', as: :callback
  post 'callbacks/:message_id(/*path)', to: 'callbacks#create'

  post 'feedback/awssns' => 'feedback#awssns'

  resources :messages
  resources :campaigns
  resources :subscribers do
    member do
      post :unsubscribe
      post :subscribe
    end
  end

  namespace :api do
    resources :events
  end

  namespace :admin do
    resources :campaigns do
      member do
        post 'publish', action: 'publish'
      end
    end
    resources :layouts do
      resources :attachments, controller: 'layouts/attachments'
    end
    resources :lists do
      resources :subscribers, controller: 'lists/subscribers'
    end
    resources :messages do
      member do
        post 'resend', action: 'resend'
      end
    end
    resources :layouts
    resources :locales
    resources :templates
  end
  root to: 'dashboard#show'
  mount Trado::Engine, at: '/'
end
