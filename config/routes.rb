# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :meeting_agendas do
  collection do
    get :autocomplete_for_issue
    get :autocomplete_for_place
    get :from_protocol
    get :ungroup
    get :group
  end
  member do
    get :send_invites
    get :resend_invites
    get :copy
    put :assert
    get :send_asserter_invite
    put :restore
  end
end
resources :meeting_members do
  collection do
    get :autocomplete_for_user
  end

  member do
    get :accept
    get :reject
  end
end
resources :meeting_participators do
  collection do
    get :autocomplete_for_user
  end

  member do
    get :accept
  end
end

resources :meeting_comments
resources :meeting_issues
resources :meeting_protocols do
  member do
    get :send_notices
    get :resend_notices
    put :assert
    get :send_asserter_invite
    put :restore
  end
end

resources :meeting_bind_issues
resources :meeting_approvers do
  collection do
    get :autocomplete_for_user
  end
end

resources :meeting_contacts do
  collection do
    get :autocomplete_for_contact
  end
end

resources :meeting_watchers do
  collection do
    get :autocomplete_for_user
  end
end

resources :meeting_room_selectors do
  collection do
    get :autocomplete_for_meeting_room
  end
end

resources :meeting_questions

resources :meeting_external_approvers do
  collection do
    get :autocomplete_for_contact
  end
end
