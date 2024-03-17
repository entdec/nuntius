# frozen_string_literal: true

Rails.application.routes.draw do
  mount Nuntius::Engine => "/nuntius"
end
