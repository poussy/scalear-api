Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  scope "/en" do
    mount_devise_token_auth_for 'User', at: 'users', controllers: {
      # registrations: 'devise/registrations',
      sessions: 'devise/sessions'
    }

    resources :users, only: [] do
      member do
        get "enroll"
        post "enroll_to_course"
        get "teacher_courses"
        # post "update_intro_watched"
        post "update_completion_wizard"
        get "get_subdomains"
      end
      collection do
        get "student"
        get "teacher"
        get "sign_angular_in"
        get "get_current_user"
        get "get_user_angular"
        get "take_angular_back"
        post "alter_pref"
        post "saml_signup"
        get "user_exist"
      end
    end
  end
end
