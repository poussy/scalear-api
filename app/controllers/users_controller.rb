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

  # def saml_signup
  # end

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

end