Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  scope "/en" do
    mount_devise_token_auth_for 'User', at: 'users', controllers: {
      registrations: 'devise/registrations',
      sessions: 'devise/sessions',
      passwords: 'devise/passwords',
      confirmations: 'devise/confirmations'
    }

    root :to => "home#index"
    get "/home/index"
    get "/home/test"
    get "home/technical_problem"
    get "home/contact_us"
    get "home/privacy"
    get "home/about"
    get "home/notifications"
    post "home/accept_course"
    post "home/reject_course"    

    post "discussions/create_comment"
    get "discussions/get_comments"
    post "discussions/vote"
    post "discussions/flag"
    post "discussions/create_post"
    get "discussions/get_posts"
    delete "discussions/delete_post"
    delete "discussions/delete_comment"
    post "discussions/vote_comment"
    post "discussions/flag_comment"
    delete "discussions/remove_all_flags"
    delete "discussions/remove_all_comment_flags"
    post "discussions/hide_post"
    post "discussions/hide_comment"
    post "discussions/update_post"



    # devise_for :users 
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

    resources :courses do
        member do
            post 'remove_student'
            post 'unenroll'
            get 'add_student'
            get 'student_show'
            get 'courseware'
            get 'courseware_teacher'
            get 'enrolled_students'
            get 'teachers'
            get 'get_selected_subdomains'
            post 'set_selected_subdomains'
            post 'save_teachers'
            post 'update_teacher'
            post 'update_student_duedate_email'
            post 'update_teacher_discussion_email'
            get 'get_student_duedate_email'
            delete 'delete_teacher'
            put 'validate_course_angular'
            get 'progress_teacher'
            get 'progress_teacher_detailed'
            get 'progress'
            post 'student_quiz'
            get 'student_notifications'
            get 'course_editor'
            get 'student_grade'
            get 'dynamic_quizzes'
            get 'student_quiz_grade'
            get 'student_lecture_grade'
            get 'send_email'
            post 'send_email_through'
            post 'send_batch_email'
            post 'send_batch_email_through'
            get 'inclass'
            get 'buttons_inclass'
            get 'get_remaining_progress'
            get 'get_total_chart'
            get 'course_editor_angular'
            get 'get_group_items_angular'
            get 'get_course_angular'
            get 'module_progress_angular'
            get 'get_total_chart_angular'
            get 'courseware_angular'
            get 'courseware'
            get 'export_csv'
            get 'export_student_csv'
            post 'new_link_angular'
            post 'sort_course_links'
            get 'export_for_transfer'
            get 'export_modules_progress'
            get 'get_role'
            get 'edit'
        end
        collection do
            get 'new'
            post 'enroll_to_course'
            get 'course_copy_angular'
            get 'get_all_teachers'
            get 'current_courses'
            post 'send_system_announcement'
        end
        
        resources :groups do #at first had it over quizzes and lectures, but then a lecture/quiz might not be part of a module! so shouldn't need module to access lecture.. could create lectures and then put them part of a group.
            member do
                get 'group_editor'
                get 'statistics'
                get 'details'
                get 'display_quizzes'
                get 'display_questions'
                get 'display_surveys'
                get 'new_link'
                get 'review_questions'
                post 'save_review_questions'
                post 'hide_invideo_quiz'
                get 'review_quizzes'
                get 'review_surveys'
                post 'review_single_survey'
                post 'display_single_survey'
                post 'get_progress'
                get 'get_remaining_progress'
                post 'get_confused'
                post 'get_survey'
                post 'get_quiz'
                post 'get_status'
                post 'get_overall_chart'
                post 'change_status'
                get 'get_lecture_progress_angular'
                get 'get_quizzes_progress_angular'
                get 'get_surveys_progress_angular'
                get 'get_all_items_progress_angular'
                get 'get_group_statistics'
                post 'new_link_angular'
                put 'validate_group_angular'
                get 'get_lecture_charts_angular'
                get 'get_module_charts_angular'
                get 'get_survey_chart_angular'
                get 'get_quiz_chart_angular'
                get 'get_student_statistics_angular'
                post 'change_status_angular'
                get 'display_quizzes_angular'
                get 'display_questions_angular'
                get 'get_student_questions'
                post 'hide_student_question'
                get 'get_inclass_active_angular'
                get 'get_module_data_angular'
                post 'module_copy'
                get 'display_all'
                get 'get_module_progress'
                get 'get_module_inclass'
                get 'get_quiz_charts'
                get 'get_survey_charts'
                get 'last_watched'
                get 'get_quiz_charts_inclass'
                post 'sort_group_links'
                get 'get_inclass_student_status'
                post 'update_all_inclass_sessions'
                get 'get_module_summary'
                get 'get_online_quiz_summary'
                get 'get_discussion_summary'
            end
            collection do
                post 'sort'
                get 'new_or_edit'
                post 'new_module_angular'
                post 'module_copy'
            end
        end
        resources :quizzes do
          member do
            get 'middle'
            get 'details'
            get 'get_questions_angular'
            put 'update_questions'
            post 'create_or_update_survey_responses'
            post 'hide_responses'
            post 'hide_response_student'
            post 'delete_response'
            post 'make_visible'
            post 'show_question_inclass'
            post 'show_question_student'
            put 'update_questions_angular'
            put 'validate_quiz_angular'
            post 'save_student_quiz_angular'
            post 'quiz_copy'
            post 'update_grade'
            post 'change_status_angular'
          end
          collection do
            post 'sort'
            post 'new_or_edit'
            post 'quiz_copy'
          end
        end
        resources :lectures do
          member do
            get 'add_quiz'
            get 'remove_quiz'
            get 'coordinates'
            get 'add_answer'
            get 'remove_answer'
            get 'get_answers'
            #get 'save_answers'
            post 'save_answers2'
            post 'save_online'
            post 'save_html'
            get 'answered'
            get 'insert_quiz'
            post 'confused'
            post 'confused_question'
            get 'seen'
            get 'new_quiz'
            get 'new_marker'
            get 'save_duration'
            post 'back'
            post 'pause'
            get 'getOldData'
            get 'getHTMLData'
            post 'update_html'
            get 'middle'
            get 'details'
            get 'get_old_data_angular'
            get 'get_html_data_angular'
            get 'get_lecture_data_angular'
            get 'online_quizzes_solved'
            get 'get_lecture_angular'
            get 'get_quiz_list_angular'
            get 'new_quiz_angular'
            post 'save_answers_angular'
            post 'add_answer_angular'
            post 'add_html_answer_angular'
            post 'remove_html_answer_angular'
            post 'remove_answer_angular'
            put 'validate_lecture_angular'
            get 'switch_quiz'
            delete 'delete_confused'
            get 'load_note'
            post 'save_note'
            delete 'delete_note'
            post 'lecture_copy'
            get 'export_notes'
            post 'update_percent_view'
            post 'change_status_angular'
            post 'create_or_update_survey_responses'
            delete 'delete_response'
            post 'confused_show_inclass'
            post 'log_video_event'
            get 'invite_student_distance_peer'
            get 'check_if_invited_distance_peer'
            get 'check_invited_student_accepted_distance_peer'
            get 'accept_invation_distance_peer'
            get 'cancel_session_distance_peer'
            get 'check_if_in_distance_peer_session'
            get 'change_status_distance_peer'
            get 'check_if_distance_peer_status_is_sync'
            get 'check_if_distance_peer_is_alive'
          end
          collection do
            post 'sort'
            get 'new_or_edit'
            get 'new_lecture_angular'
            post 'lecture_copy'

          end
    end


    resources :announcements
    end    
    
    resources :online_markers do
        member do
            put 'validate_name'
            post 'update_hide'
        end
            collection do
            get 'get_marker_list'
        end
    end

    resources :custom_links do
      collection do
        post 'sort_course'
        post 'link_copy'      
      end
      member do
        put 'validate_custom_link'
        post 'link_copy'
      end
    end

    resources :online_quizzes do
      collection do
        get 'get_quiz_list_angular'
      end
      member do
        get  'get_chart_data'
        put  'validate_name'
        post 'vote_for_review'
        post 'unvote_for_review'
        post 'hide_responses'
        post 'update_inclass_session'
        get 'get_inclass_session_votes'
        post 'update_grade'
      end
    end

    resources :shared_items do
      member do
        post 'accept_shared'
        post 'update_shared_data'
        post 'reject_shared'
      end
      collection do
        get 'show_shared'
      end
    end

    resources :dashboard do
      collection do
        get 'get_dashboard'
        get 'dynamic_url'
      end
    end
    
    resources :impressionate do
      collection do
        delete :destroy
        get 'impressionate_as'
      end
    end

  end
end
