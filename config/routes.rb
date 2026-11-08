# frozen_string_literal: true

Nuntius::Engine.routes.draw do
  namespace :inbound_messages do
    resource :twilio_inbound_smses
  end

  get "callbacks/:message_id(/*path)", to: "callbacks#create", as: :callback
  post "callbacks/:message_id(/*path)", to: "callbacks#create"

  post "feedback/awssns" => "feedback#awssns"
  post "feedback/lettermint" => "feedback#lettermint", :as => :lettermint_feedback

  resources :messages do
    # Email tracking routes
    member do
      get "pixel", to: "messages#pixel", as: :tracking_pixel
      get "link", to: "messages#link", as: :tracking_link
    end
  end
  resources :campaigns
  resources :subscribers do
    member do
      get :unsubscribe
      post :unsubscribe
      get :subscribe
      post :subscribe
    end
  end

  namespace :api do
    resources :events
  end

  namespace :admin do
    resources :campaigns do
      member do
        post "schedule", action: "schedule"
        post "deschedule", action: "deschedule"
        post "cancel", action: "cancel"
        # The test button submits the campaign form, a PATCH
        match "send_test", action: "send_test", via: [:post, :patch]
        get "media", to: "media#index", defaults: {owner: "campaign"}
        post "media", to: "media#create", defaults: {owner: "campaign"}
        post "media/compile", to: "media#compile", defaults: {owner: "campaign"}
        get "translations", to: "translations#index", defaults: {owner: "campaign"}
        patch "translations", to: "translations#update", defaults: {owner: "campaign"}
      end
      resources :attachments, controller: "satis/attachments"
    end
    resources :layouts do
      member do
        get "media", to: "media#index", defaults: {owner: "layout"}
        post "media", to: "media#create", defaults: {owner: "layout"}
        post "media/compile", to: "media#compile", defaults: {owner: "layout"}
        get "translations", to: "translations#index", defaults: {owner: "layout"}
        patch "translations", to: "translations#update", defaults: {owner: "layout"}
      end
      resources :attachments, controller: "satis/attachments"
    end
    resources :lists do
      resources :subscribers, controller: "lists/subscribers" do
        collection do
          get :import
          post :import
        end
      end
    end
    resources :messages do
      member do
        post "resend", action: "resend"
      end
    end
    resources :layouts
    resources :locales
    resources :templates do
      resources :attachments, controller: "satis/attachments"
      member do
        get "media", to: "media#index", defaults: {owner: "template"}
        post "media", to: "media#create", defaults: {owner: "template"}
        post "media/compile", to: "media#compile", defaults: {owner: "template"}
        get "translations", to: "translations#index", defaults: {owner: "template"}
        patch "translations", to: "translations#update", defaults: {owner: "template"}
        # The conversion button submits the template form, a PATCH
        match "convert", action: "convert", via: [:post, :patch]
      end
    end
  end
  root to: "dashboard#show"

  # The email editor compiles MJML here: tess_edit.compile_path
  mount TessEdit::Engine => "/tess_edit"
end
