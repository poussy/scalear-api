class UsersController < ApplicationController

#   before_action :authenticate_user!, :except => [:student, :teacher, :sign_angular_in, :take_angular_back]  #authenticate meaning is he signed in
#   before_action :correct_user, :except => [:sign_angular_in, :get_current_user] #, :student, :teacher, :teacher_courses,
#   before_action :already_signed_in, :only => [:student, :teacher]
#   skip_before_action :authenticate_user!, :only =>[:get_current_user]
#   load_and_authorize_resource
#   load_and_authorize_resource :only => [:watched_intro]
#   skip_before_action :check_user_signed_in?, :only => [:get_current_user, :sign_angular_in, :saml_signup, :user_exist]


  def already_signed_in
    if current_user
      redirect_to root_url, :alert => t('controller_msg.you_are_signed_in')
    end
  end

  def update_completion_wizard
    if current_user
      current_user.completion_wizard = params[:completion_wizard]
      current_user.save(:validate => false)
      render json: {}
    end
  end
  # def update_intro_watched
  #   if current_user
  #     current_user.completion_wizard[:intro_watched] = params[:intro_watched]
  #     current_user.save(:validate => false)
  #     render json: {}
  #   end
  # end
  # def correct_user
    # # Checking to see if the current user is taking the course OR teaching the course, otherwise he is not authorised.
    # @user=User.find(params[:id])
    # if @user!=current_user
      # render json: "You are not authorized", status: 403
    # end
  # end

  # def index
    # authorize! :index, @user, :message => t('controller_msg.not_authorized_as_admin')
    # @users = User.all
  # end

  # def show
    # authorize! :show, @user, :message => t('controller_msg.not_authorized_as_admin') #I added this
    # @user = User.find(params[:id])
  # end
#
  # def update
    # authorize! :update, @user, :message => t('controller_msg.not_authorized_as_admin')
    # @user = User.find(params[:id])
    # if @user.update_attributes(params[:user], :as => :admin)
      # redirect_to users_path, :notice => t('controller_msg.user_updated')
    # else
      # redirect_to users_path, :alert => t('controller_msg.unable_update_user')
    # end
  # end
#
  # def destroy
    # print "in destroy"
    # authorize! :destroy, @user, :message => t('controller_msg.not_authorized_as_admin')
    # user = User.find(params[:id])
    # unless user == current_user
      # user.destroy
      # redirect_to users_path, :notice => t('controller_msg.user_deleted')
    # else
      # redirect_to users_path, :notice => t('controller_msg.cant_delete_yourself')
    # end
  # end

  # def enroll
  # end
  # def enroll_to_course
    # @course = Course.find_by_unique_identifier(params[:unique_identifier])
    # if @course.nil?
      # redirect_to enroll_user_path, :alert => t('controller_msg.course_does_not_exist')
    # elsif current_user.courses.include?(@course)
      # redirect_to enroll_user_path, :alert => t('controller_msg.already_enrolled')
    # else
      # @course.users<<current_user
      # redirect_to "/#{I18n.locale}", :notice => t('controller_msg.already_enrolled_in', course: @course.name )
    # end
  # end

   #def student
   #  @user = User.new
   #end
   #
   #def teacher
   #  @user = User.new
   #end

  def get_current_user
    result = {:user => current_user.to_json(:include => {:roles=>{:only => :id}}, :methods => [:info_complete, :intro_watched]), :signed_in => user_signed_in?}
    if user_signed_in?
      result[:profile_image] = Digest::MD5.hexdigest(current_user.email);
      if current_user.is_teacher_or_admin?
        result[:invitations] = Invitation.where("lower(email) = ?", current_user.email.downcase).count
        result[:shared] = current_user.shared_withs.where(:accept => false).count
        result[:accepted_shared] = current_user.shared_withs.where(:accept => true).count
      end
    end
    render :json => result
  end

  def sign_angular_in
    session[:angular_redirect]= params[:angular_redirect]
    #session[:locale]=params[:locale]
    redirect_to user_omniauth_authorize_path(:doorkeeper) #:locale => session[:locale]
  end

  def get_user_angular
    user = User.find(params[:user_id])
    #respond_to do |format|
      result =  {:user => user.to_json(:include => :roles, :methods => [:info_complete, :intro_watched]), :profile_image => Digest::MD5.hexdigest(user.email)}
      render :json => result
    #end
  end

  def alter_pref
    user = User.find(current_user.id)
    user.discussion_pref = params[:privacy]
    user.save(:validate => false)
    render :json =>{}
  end

  def saml_signup
    params[:user][:password] = Devise.friendly_token[0,20]
    params[:user][:completion_wizard] = {:intro_watched => false}
    user =User.new(params[:user])
    user.skip_confirmation!
    user.roles << Role.find(1)
    user.roles << Role.find(2)
    if user.save
      sign_in user
      render json: {:user => user}
    else
      render json: {errors: user.errors}, status: :unprocessable_entity
    end

  end

  def user_exist
    if User.find_by_email(params[:email]).nil?
      render json: {}
    else
      render json: {errors: ["Email already exist, please try to login"]}, :status => 400
    end
  end

  def get_subdomains
    subdomains = []
    domain = "empty_domain"
    if !current_user.is_administrator?
      domain = UsersRole.where(:user_id => current_user.id, :role_id => 9)[0].admin_school_domain
      if  domain[0] == "."
        email = domain.match(/(\w+\.\w+$)/)[1]
        subdomains = current_user.get_subdomains(email)
        subdomains = subdomains.select {|domain| !domain.include?("stud") }
      else
        subdomains.append(domain)
      end
    end
    if domain.blank?
      render json: {errors: "please contact the scalable learning team."}, :status => 500
    else
      render json: {subdomains: subdomains}
    end
  end

  # def take_angular_back
    # redirect_to session[:angular_redirect]
  # end

   # def teacher_courses
    # @teacher_name = User.find(params[:id]).name
    # @courses = User.find(params[:id]).subjects_to_teach
  # end

end