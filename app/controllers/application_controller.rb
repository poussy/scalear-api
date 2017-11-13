class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include CanCan::ControllerAdditions

  include CanCan::ControllerAdditions

  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found


  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:last_name, :university, :user, :name, :screen_name, :registration])
    devise_parameter_sanitizer.permit(:account_update, keys: 
      [:last_name, :university, :user, :name, :screen_name, :registration, :link, :bio, :first_day])
  end

  def check_user_signed_in? #401 not authenticated(devise) #403 not authorized/not allowed (cancan)
    if !user_signed_in?
       render json:{:errors=>[t("controller_msg.not_logged_in")]}, status: 401
    end
  end
	
  rescue_from CanCan::AccessDenied do |exception|
		render json: {:errors=>[ I18n.t("controller_msg.you_are_not_authorized") ]}, status: 403
	end

end
