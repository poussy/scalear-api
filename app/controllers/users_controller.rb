class UsersController < ApplicationController


  def already_signed_in
    if current_user
      redirect_to root_url, :alert => t('controller_msg.you_are_signed_in')
    end
  end

 
  def get_current_user
    
    result = {:user => current_user.to_json(:methods => [:info_complete, :roles, :intro_watched]), :signed_in => user_signed_in?  } 
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

  

end