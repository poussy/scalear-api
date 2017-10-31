class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken

  before_action :configure_permitted_parameters, if: :devise_controller?

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:last_name, :university, :user, :name, :screen_name, :registration])
    devise_parameter_sanitizer.permit(:account_update, keys: 
      [:last_name, :university, :user, :name, :screen_name, :registration, :link, :bio, :first_day])
    
  end


	rescue_from CanCan::AccessDenied do |exception|
		render json: {:errors=>[ "controller_msg.you_are_not_authorized" ]}, status: 403
	end
end

end
