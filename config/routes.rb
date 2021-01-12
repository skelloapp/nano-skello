Rails.application.routes.draw do
  namespace :shops do
    resources :shifts
  end
end
