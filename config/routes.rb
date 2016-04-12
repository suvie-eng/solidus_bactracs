Spree::Core::Engine.routes.draw do
  get  '/shipstation' => 'shipstation#export'
  post '/shipstation' => 'shipstation#shipnotify'
end
