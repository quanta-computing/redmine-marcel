# Marcel plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :vacations do
  member do
    post 'validate'
  end
end
