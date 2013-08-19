# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :meeting_agendas do
  collection do
    get 'autocomplete_for_issue'
  end
  member do
    resources :meeting_members
  end
end
resources :meeting_protocols
