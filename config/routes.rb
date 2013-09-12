# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :meeting_agendas do
  collection do
    get 'autocomplete_for_issue'
    get 'autocomplete_for_place'
  end
  member do
    get 'send_invites'
    get 'resend_invites'
  end
end
resources :meeting_members do
  collection do
    get 'autocomplete_for_user'
  end
end
resources :meeting_participators do
  collection do
    get 'autocomplete_for_user'
  end
end

resources :meeting_comments
resources :meeting_issues
resources :meeting_protocols do
  member do
    get 'send_notices'
    get 'resend_notices'
  end
end

resources :meeting_bind_issues
resources :meeting_approvers do
  collection do
    get 'autocomplete_for_user'
  end
end
