class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
      # if user.admin?
      #   can :manage, :all
      # else
      #   can :read, :all
      # end
    if user.has_role? 'User'
        can [:new, :create, :enroll_to_course, :index,  :current_courses], Course                
        ## Teacher Abilities for Course table
        can [:teachers,:get_group_items, :course_editor_angular, :get_course_angular, :delete_teacher, :update_teacher, :save_teachers, :remove_student, :send_batch_email_through, 
            :send_email_through, :show, :destroy, :update, :send_email, :enrolled_students, :module_progress_angular, :get_total_chart_angular, :validate_course_angular, :export_csv, 
            :export_student_csv, :course_copy_angular,:get_all_teachers, :new_link_angular, :sort_course_links, :export_for_transfer, :export_modules_progress ,:get_selected_subdomains ,
            :set_selected_subdomains ,:update_teacher_discussion_email ], Course do |course|
                course.correct_teacher(user)
            end
        # ## Student Abilities for Course table
        can [ :getCourse, :show, :courseware_angular, :courseware, :unenroll,:update_student_duedate_email , :get_student_duedate_email], Course do |course|
            course.correct_student(user)
        end

    end

  end
end
