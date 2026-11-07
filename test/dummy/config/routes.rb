# frozen_string_literal: true

Rails.application.routes.draw do
  mount Nuntius::Engine => "/nuntius"
  mount Mensa::Engine => "/mensa"
  mount Liquidum::Engine => "/liquidum"

  root to: redirect("/nuntius")
end
