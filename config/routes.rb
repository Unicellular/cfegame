Cfegame::Application.routes.draw do
  root 'home#lobby'
  resources :users
  get '/auth/:provider/callback' => 'sessions#create'
  get '/auth/failure' => 'sessions#failure'
  get '/signout' => 'sessions#destroy', as: :signout
  get '/signin' => 'sessions#new', as: :signin
  post '/open' => 'home#open', as: :open
  patch '/join/:id/:team_id' => 'home#join', as: :join
  get '/game/:id' => 'home#game', as: :game
  get '/find_opponent/:id/:player_id' => 'game#index'
end
