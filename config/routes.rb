Spree::Core::Engine.routes.draw do
  get  '/shipstation' => Spree::MapQueryStringApp
  post '/shipstation' => Spree::MapQueryStringApp
end
