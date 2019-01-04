Rails.application.routes.draw do
  root 'welcome#index'
  post 'search', to: 'welcome#search'
end
