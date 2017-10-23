class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken

  before_action :configure_permitted_parameters, if: :devise_controller?

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:last_name])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:last_name])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:registration])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:session])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:user])
    
  end

end
