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
  get '/find_opponent/:gid/:pid' => 'game#index'
  get '/use_cards/:gid/:pid' => 'players#use_cards'
  get '/draw/:gid/:pid' => 'players#draw'
  get '/discard/:gid/:pid/:card_id' => 'players#discard'
  get '/turn_end/:gid/:pid/' => 'players#turn_end'
  get '/status/:gid/:pid/' => 'game#status'
end
