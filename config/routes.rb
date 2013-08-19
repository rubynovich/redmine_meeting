# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :meeting_agendas do
  collection do
    get 'autocomplete_for_issue'
  end
end
resources :meeting_members do
  collection do
    get 'autocomplete_for_user'
  end
end

resources :meeting_protocols
