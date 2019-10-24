require 'tempfile'

class UsersController < ApplicationController
  # def already_signed_in
  #   if current_user
  #     redirect_to root_url, :alert => I18n.t('controller_msg.you_are_signed_in')
  #   end
  # end

  def get_current_user    
    if current_user && !current_user.is_school_administrator? 
      result = {:user => current_user.to_json(:include => {:roles=>{:only => :id}}, :methods => [:info_complete, :intro_watched]), :signed_in => user_signed_in?} 
    else 
      result = {:user => current_user.to_json(:include => {:roles=>{:only => :id}}, :methods => [:info_complete, :intro_watched, :get_school_administrator_domain] ), :signed_in => user_signed_in?}       
    end 
    if user_signed_in?
      result[:profile_image] = Digest::MD5.hexdigest(current_user.email);
      result[:invitations] = Invitation.where("lower(email) = ?", current_user.email.downcase).count
      result[:shared] = current_user.shared_withs.where(:accept => false).count
      result[:accepted_shared] = current_user.shared_withs.where(:accept => true).count
    end
    render :json => result    
  end

  def user_exist
    if User.find_by_email(params[:email]).nil?
      render json: {}
    else
      render json: {errors: ["Email already exist, please try to login"]}, :status => 400
    end
  end

  def update_completion_wizard
    if current_user
      current_user.completion_wizard = params[:completion_wizard]
      current_user.save(:validate => false)
      render json: {}
    end
  end
  
  # def sign_angular_in
  # end

  # def get_user_angular
  # end

  def alter_pref
    user = User.find(current_user.id)
    user.discussion_pref = params[:privacy]
    user.save(:validate => false)
    render :json =>{}
  end

  def saml_signup
    params_user = user_params
    params_user[:password] = Devise.friendly_token[0,20]
    params_user[:completion_wizard] = {:intro_watched => false}
    user =User.new(params_user)
    user.skip_confirmation!
    user.roles << Role.find(1)
    user.roles << Role.find(2)
    if user.save
      token = user.create_new_auth_token
      render json: {user: user, token: token}
    else
      render json: {errors: user.errors}, status: :unprocessable_entity
    end

  end

  def get_subdomains
    subdomains = []
    domain = "empty_domain"
    if !current_user.is_administrator?
      user_role = UsersRole.where(:user_id => current_user.id, :role_id => 9)[0]
      domain = user_role.admin_school_domain
      if  domain == "all"
        email = user_role.organization.domain
        subdomains = current_user.get_subdomains(email)
        subdomains = subdomains.select {|domain| !domain.include?("stud") }
      else
        domain = user_role.organization.domain
        subdomains.append(domain)
      end
    end
    if domain.blank?
      render json: {errors: "please contact the scalable learning team."}, :status => 500
    else
      render json: {subdomains: subdomains}
    end
  end
  
  def get_welcome_message 
    if current_user.is_school_administrator? 
      render json: {welcome_message: current_user.organizations[0].welcome_message, domain: current_user.organizations[0].domain} 
    else 
      organization = Organization.all.detect { |organization| current_user.email.end_with?(organization.domain) } 
      if organization 
        render json: {welcome_message: organization.welcome_message } 
      else 
        render json: {}         
      end 
    end 

  end 

  def submit_welcome_message 
    if current_user.organizations[0].update_attributes(:welcome_message => params[:welcome_message]) 
      render json: {organization: current_user.organizations[0]} 
    else 
      render json: {:errors => current_user.organizations[0].errors }, :status => :unprocessable_entity 
    end 
  end 

  def agree_to_privacy_policy
    user = User.find(params['id'])
    user.policy_agreement= {'date' => DateTime.now, 'ip' => request.remote_ip}
    if user.save    
      render json: user
    else
      render json: user.errors
    end
  end
  def create_user_activity_file(email)

    user = User.find_by_email(email)
    csv_files={}
    
    csv_files[:user_data]= CSV.generate do |csv_user_data|
    csv_files[:roles]= CSV.generate do |csv_roles|
    csv_files[:student_courses]= CSV.generate do |csv_student_courses|
    csv_files[:teacher_courses]= CSV.generate do |csv_teacher_courses|
    csv_files[:lecture_views] = CSV.generate do |csv_lecture_views|
    csv_files[:quiz_grades] = CSV.generate do |csv_quiz_grades|
    csv_files[:online_quiz_grades] = CSV.generate do |csv_online_quiz_grades|
    csv_files[:free_answers] = CSV.generate do |csv_free_answers|
    csv_files[:free_online_quiz_grades]= CSV.generate do |csv_free_online_quiz_grades|
    csv_files[:quiz_statuses]= CSV.generate do |csv_quiz_statuses|
    csv_files[:assignment_statuses]= CSV.generate do |csv_assignment_statuses|
    csv_files[:assignment_item_statuses]= CSV.generate do |csv_assignment_item_statuses|
    csv_files[:video_events]= CSV.generate do |csv_video_events|
    csv_files[:confuseds]= CSV.generate do |csv_confuseds|
    csv_files[:video_notes]= CSV.generate do |csv_video_notes|
    csv_files[:invitations]= CSV.generate do |csv_invitations|
    csv_files[:announcements]= CSV.generate do |csv_announcements|
    csv_files[:discussions]= CSV.generate do |csv_discussions|
            
            user_columns = ["id","provider","uid","remember_created_at","sign_in_count","current_sign_in_at","last_sign_in_at","current_sign_in_ip","last_sign_in_ip","failed_attempts","name","email","created_at","updated_at","last_name",
                    "screen_name","university","link","discussion_pref","completion_wizard","first_day","canvas_id","canvas_last_signin","saml","policy_agreement"]

            csv_user_data << user_columns
            csv_user_data << user.attributes.values_at(*user_columns)

            csv_roles << Role.column_names
            user.roles.each do |role|
                    csv_roles << role.attributes.values_at(*Role.column_names)
            end

            csv_student_courses << Course.column_names
            Enrollment.where(user_id:user.id).each do |enrollment|
                    csv_student_courses << Course.find(enrollment.course_id).attributes.values_at(*Course.column_names)
            end

            csv_teacher_courses << Course.column_names
            TeacherEnrollment.where(user_id:user.id).each do |enrollment|
                    csv_teacher_courses << Course.find(enrollment.course_id).attributes.values_at(*Course.column_names)
            end

            csv_lecture_views << LectureView.column_names
            user.lecture_views.each do |view|
                    csv_lecture_views << view.attributes.values_at(*LectureView.column_names)
            end

            csv_quiz_grades << QuizGrade.column_names
            user.quiz_grades.each do |grade|
                    csv_quiz_grades << grade.attributes.values_at(*QuizGrade.column_names)
            end

            csv_online_quiz_grades << OnlineQuizGrade.column_names
            user.online_quiz_grades.each do |grade|
                    csv_online_quiz_grades << grade.attributes.values_at(*OnlineQuizGrade.column_names)
            end

            csv_free_answers << FreeAnswer.column_names
            user.free_answers.each do |answer|
                    csv_free_answers << answer.attributes.values_at(*FreeAnswer.column_names)
            end

            csv_free_online_quiz_grades << FreeOnlineQuizGrade.column_names
            user.free_online_quiz_grades.each do |grade|
                    csv_free_online_quiz_grades << grade.attributes.values_at(*FreeOnlineQuizGrade.column_names)
            end

            csv_quiz_statuses << QuizStatus.column_names
            user.quiz_statuses.each do |status|
                    csv_quiz_statuses << status.attributes.values_at(*QuizStatus.column_names)
            end

            csv_assignment_statuses << AssignmentStatus.column_names
            user.assignment_statuses.each do |status|
                    csv_assignment_statuses << status.attributes.values_at(*AssignmentStatus.column_names)
            end

            csv_assignment_item_statuses << AssignmentItemStatus.column_names
            user.assignment_item_statuses.each do |status|
                    csv_assignment_item_statuses << status.attributes.values_at(*AssignmentItemStatus.column_names)
            end

            csv_video_events << VideoEvent.column_names
            user.video_events.each do |event|
                    csv_video_events << event.attributes.values_at(*VideoEvent.column_names)
            end

            csv_confuseds << Confused.column_names
            user.confuseds.each do |confused|
                    csv_confuseds << confused.attributes.values_at(*Confused.column_names)
            end

            csv_video_notes << VideoNote.column_names
            user.video_notes.each do |note|
                    csv_video_notes << note.attributes.values_at(*VideoNote.column_names)
            end

            csv_invitations << Invitation.column_names
            user.invitations.each do |invitation|
                    csv_invitations << invitation.attributes.values_at(*Invitation.column_names)
            end

            csv_announcements << Announcement.column_names
            user.announcements.each do |announcement|
                    csv_announcements << announcement.attributes.values_at(*Announcement.column_names)
            end

            csv_discussions << Forum::Post.get('column_names')
            Forum::Post.get("user_posts", {:user_id => user.id}).each do |post|
                    csv_discussions << post.values_at(*Forum::Post.get('column_names'))
            end

      end
      end
      end
      end
      end
      end
      end
      end
      end
      end
      end
      end
      end
      end
      end
      end
      end
      end

      file_name = user.name+".zip"
      t = Tempfile.new(file_name)
      Zip::ZipOutputStream.open(t.path) do |z|
              csv_files.each do |key,value|
                      z.put_next_entry("#{key}.csv")
                      z.write(value)
              end
      end
      
      t.close

      return {:path=>t.path,:file_name=>file_name}
  end  
  def generate_user_activity_file
      file_info = create_user_activity_file(params["email"])
      send_file(file_info[:path],:file_name=>file_info[:file_name])
  end  
  def filter_unfound_users(emails_array)
    found = emails_array.map{|e| e if User.find_by_email(e)}.compact
    return found
  end
  def filter_out_of_domain_users(students_emails,admin_user)
      subdomains = admin_user.get_subdomains(admin_user.email)
      in_domain_students_email = students_emails.map{|email| email if subdomains.include?email.split('@')[1]}.compact
      out_of_domain_students_email = students_emails - in_domain_students_email
      return  [in_domain_students_email , out_of_domain_students_email]
  end  
  def send_user_activity_file
     
     students_emails = params["student_email"].delete(' ').split(',')
     admin_user = User.find_by_email(params['admin_email'])
     students_zipped_data = []
     not_found_students = []
     out_domain_students =[]
     in_domain_students = []
     
     found_students = filter_unfound_users(students_emails)
     not_found_students = students_emails - found_students

     in_domain_students,out_domain_students = filter_out_of_domain_users(found_students,admin_user)
     students_zipped_data = in_domain_students.map{|student_email| create_user_activity_file(student_email)} if in_domain_students.length >0

     UserMailer.many_attachment_email(admin_user, Course.last, students_zipped_data, I18n.locale).deliver if students_zipped_data.length > 0
     
     if ((not_found_students.length > 0 || out_domain_students.length>0) && students_zipped_data.length == 0 )#all accounts unprocessable
      render json: { unprocessable_students: not_found_students+out_domain_students,notice:"listed students accounts don't exist or out of school domain"}
     elsif not_found_students.length == 0 && out_domain_students.length == 0 #all accounts processable
      render json: { notice:"All listed students accounts exists"}
     else
      render json: { processable_students: in_domain_students , unprocessable_students: not_found_students+out_domain_students,notice:"some of the listed students don't exist or out of school domain "}
     end
  end
  def validate_user
    #skip password confirmation in case of saml
    if params['user']['password'].blank? && params['is_saml']
      params['password'] = Devise.friendly_token[0,20]
      params['password_confirmation'] = params['password']
    end
    user = User.new(email: params['user']['email'],last_name: params['user']['last_name'], name: params['user']['name'], password: params['password'], screen_name:params['user']['screen_name'], 
      university: params['user']['university'])
    if user.valid?
      if params['password'] != params['password_confirmation']
        render json: {errors: {password_confirmation:["Doesn't match password"]}}, :status => :unprocessable_entity 
      elsif params['last_name'].blank?
        render json: {errors: {last_name:["can't be blank"]}}, :status => :unprocessable_entity 
      elsif params['university'].blank?
        render json: {errors: {university:["can't be blank"]}}, :status => :unprocessable_entity 
      else
        render json: user
      end
    else
      render json: {errors: user.errors}, :status => :unprocessable_entity 
    end

  end

  private 

  def user_params
    params.require(:user).permit(:email,:name,:last_name,:university,:password,:screen_name,:saml)
  end

end

