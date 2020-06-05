class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
        
    if user.has_role? 'User'
        
      ##Course
        can [:new, :create, :enroll_to_course, :index,  :current_courses], Course                
        ## Teacher Abilities for Course table
        can [:teachers,:get_group_items, :course_editor_angular, :get_course_angular, :delete_teacher, :update_teacher, :save_teachers, :remove_student, 
            :send_batch_email_through, :send_email_through, :show, :destroy, :update, :send_email, :enrolled_students, :module_progress_angular, :get_total_chart_angular,
            :validate_course_angular, :export_csv, :export_student_csv, :course_copy_angular,:get_all_teachers, :new_link_angular, :sort_course_links, :export_for_transfer,:send_course_to_mail, :send_course_txt_to_mail,
            :export_modules_progress ,:get_selected_subdomains , :set_selected_subdomains ,:update_teacher_discussion_email, :get_role ], Course do |course|
                course.correct_teacher(user)
        end
        # ## Student Abilities for Course table
        can [ :getCourse, :show, :courseware_angular, :courseware, :unenroll,:update_student_duedate_email , :get_student_duedate_email, :get_role], Course do |course|
            course.correct_student(user)
        end


      ## Group
        can [:create, :index, :update, :destroy, :show,:new_module_angular, :new_link_angular, :sort, :validate_group_angular, :get_group_statistics, 
             :get_lecture_progress_angular, :get_quizzes_progress_angular, :get_surveys_progress_angular, :get_all_items_progress_angular, :get_module_charts_angular,
             :get_lecture_charts_angular, :get_quiz_chart_angular, :get_survey_chart_angular, :get_student_statistics_angular, :change_status_angular, 
             :display_quizzes_angular, :display_questions_angular, :hide_invideo_quiz, :get_student_questions, :hide_student_question, :get_inclass_active_angular,
             :module_copy,:display_all, :get_progress_module, :get_module_progress, :get_module_inclass, :get_quiz_charts, :get_survey_charts, :get_quiz_charts_inclass,
             :update_all_inclass_sessions, :get_module_summary, :get_online_quiz_summary, :get_discussion_summary, :export_module_timeline_csv], Group do |group|
                group.course.correct_teacher(user)
        end
        can [:get_survey_chart_angular, :get_module_data_angular, :last_watched, :get_inclass_student_status, :get_module_summary, :get_online_quiz_summary, 
             :get_discussion_summary], Group do |group|
                group.course.correct_student(user)
        end

      ## Lecture
        can [:create, :index, :update, :destroy, :show, :new_lecture_angular, :get_old_data_angular, :get_html_data_angular, :new_quiz_angular, :new_marker,
             :save_answers_angular, :add_answer_angular, :add_html_answer_angular, :remove_html_answer_angular, :remove_answer_angular, :sort, :validate_lecture_angular, 
             :lecture_copy, :export_lecture_to_feedbackfruit,  :create_or_update_survey_responses, :update_vimeo_video_data,:delete_complete_link,:get_vimeo_upload_details,:get_uploading_status, :get_vimeo_video_id,
             :delete_vimeo_video_angular,:register_YT_api_request_angular, :update_vimeo_table,:change_status_angular, :delete_response, :confused_show_inclass], Lecture do |lecture|
                lecture.course.correct_teacher(user)
        end
        can [:show, :get_lecture_data_angular, :confused, :back, :pause, :confused_question, :save_online, :save_html, :save_note, :delete_note ,:load_note, :switch_quiz, 
             :delete_confused, :export_notes, :update_percent_view, :log_video_event,:invite_student_distance_peer,:check_if_invited_distance_peer, 
             :check_invited_student_accepted_distance_peer, :accept_invation_distance_peer, :cancel_session_distance_peer,:check_if_in_distance_peer_session, 
             :change_status_distance_peer, :check_if_distance_peer_status_is_sync , :check_if_distance_peer_is_alive], Lecture do |lecture|
                lecture.course.correct_student(user)
            end
          
        can :manage, CustomLink do |link|
                link.course.correct_teacher(user)
            end

        ## Quiz
        can [:new_or_edit, :create, :index, :update, :destroy, :show, :get_questions_angular, :update_questions_angular, :validate_quiz_angular, 
             :make_visible, :hide_responses, :hide_response_student, :create_or_update_survey_responses, :delete_response, :show_question_inclass,
             :show_question_student,:quiz_copy,  :change_status_angular, :update_grade], Quiz do |quiz|
                quiz.course.correct_teacher(user)
            end
        can [:show, :get_questions_angular, :save_student_quiz_angular], Quiz do |quiz|
                quiz.course.correct_student(user)
            end
        
        ## OnlineQuiz
        can [:create, :index, :update, :destroy, :show, :get_quiz_list_angular, :validate_name,:hide_responses, 
              :update_inclass_session, :get_chart_data, :get_inclass_session_votes , :update_grade], OnlineQuiz do |online_quiz|
                online_quiz.course.correct_teacher(user)
              end
              
        can [:vote_for_review,:unvote_for_review], OnlineQuiz do |online_quiz|
          online_quiz.course.correct_student(user)
        end
        

      ## Announcement
        can :manage, Announcement do |announcement|
              announcement.course.correct_teacher(user)
        end
        can :index, Announcement do |announcement|
              announcement.course.correct_student(user)
        end

        ##SharedItem
        can [:create], SharedItem
        can [:update], SharedItem, :shared_by_id => user.id
        can [:show, :show_shared, :accept_shared, :reject_shared, :update_shared_data, :destroy], SharedItem, :shared_with_id => user.id

      ## Online Marker 
        can [:create, :update, :destroy, :get_marker_list, :validate_name, :update_hide], OnlineMarker do |online_marker|
              online_marker.course.correct_teacher(user)
        end
    end
    if(user.has_role?'Administrator')
      can [:send_system_announcement], Course
    end
    
    if !(user.has_role? 'User') && !(user.has_role? :admin) && !(user.has_role? :administrator)
      #can :index, Course  #so that people without role can live until they get a role.
      #can [:sign_angular_in,:get_current_user], User
      can [:student,:teacher, :alter_pref, :saml_signin, :saml_signup, :user_exist, :get_domain], User
    end

  end
end
