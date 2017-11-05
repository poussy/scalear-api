Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  scope "/en" do
    mount_devise_token_auth_for 'User', at: 'users', controllers: {
      registrations: 'devise/registrations',
      sessions: 'devise/sessions',
      passwords: 'devise/passwords',
      confirmations: 'devise/confirmations'
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

  end
end
