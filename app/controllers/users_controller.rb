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

