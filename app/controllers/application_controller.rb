class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include CanCan::ControllerAdditions

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_locale
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def append_info_to_payload(payload)
    super
    payload[:ip] = request.remote_ip
    if !current_user.nil?
      payload[:user_id] = current_user.id if current_user.id
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:last_name, :university, :user, :name, :screen_name, :registration])
    devise_parameter_sanitizer.permit(:account_update, keys: 
      [:last_name, :university, :user, :name, :screen_name, :registration, :link, :bio, :first_day, :email, :saml])
  end

  def check_user_signed_in? #401 not authenticated(devise) #403 not authorized/not allowed (cancan)
    if !user_signed_in?
       render json:{:errors=>[I18n.t("controller_msg.not_logged_in")]}, status: 401
    end
  end
	
  rescue_from CanCan::AccessDenied do |exception|
		render json: {:errors=>[ I18n.t("controller_msg.you_are_not_authorized") ]}, status: 403
  end


 
  def routing_error 
    raise ActionController::RoutingError.new(params[:path]) 
  end 
  rescue_from ActionController::RoutingError, :with => :render_not_found 
 
  def render_not_found 
    render json: {:errors=>["URL '#{params[:path]}' does not exist"]}, status: 404
  end 

  def record_not_found
    render :json => {errors:[I18n.t("controller_msg.record_not_found")]}, status:404
    true
  end

  def set_locale
    I18n.locale = params[:locale]||I18n.default_locale
  end

  def self.default_url_options
    { locale: I18n.locale }
  end

end

 # adding functionality to the Time class.
class Time
    def round(seconds = 60)
        Time.at((self.to_f / seconds).round * seconds).utc
    end

    def floor(seconds = 60)
        Time.at((self.to_f / seconds).floor * seconds).utc
    end
    
    def ceil(seconds = 60)
        Time.at((self.to_f / seconds).ceil * seconds).utc
    end
    
    def self.seconds_to_time(seconds)
        Time.at(seconds).utc.strftime("%H:%M:%S")
    end
end
