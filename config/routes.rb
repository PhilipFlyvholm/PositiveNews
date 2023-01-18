Rails.application.routes.draw do
  root "articles#index"
  get "admin/validate", to: "admin/validate#index"
  put "admin/validate/:id/:score", to: "admin/validate#validate"
  delete "admin/validate/:id", to: "admin/validate#destroy"
  resources :articles
end
