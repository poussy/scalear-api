class Devise::SessionsController < DeviseTokenAuth::SessionsController
#   prepend_before_action :require_no_authentication, :only => [ :new, :create ]
#   prepend_before_action :allow_params_authentication!, :only => :create
  prepend_before_action { request.env["devise.skip_timeout"] = true }

  respond_to :json
  # GET /resource/sign_in
  def new
    p 'sessionsssssssssss newwwwwww'
    resource = build_resource(nil, :unsafe => true)
    clean_up_passwords(resource)
    redirect_to "#/users/login"
  end

  # POST /resource/sign_in
  def create
    puts "in create!!!!"
    super
  end

  # DELETE /resource/sign_out
  def destroy
    redirect_path = after_sign_out_path_for(resource_name)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out
    puts "IN DESTROY!!!!!!"
    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.json{
        render :json => {:nothing => true}
      }
      format.html{
        puts "in html"
        redirect_to redirect_path }
      format.all do
        puts "in all"
        head :no_content
      end
    end
  end

  protected

  # def increment_login_counter
  #   if session[:login_counter].nil?
  #     session[:login_counter] = 0      
  #   end
  #   session[:login_counter] += 1
  #   session[:login_time] = Time.now
  # end

  # def get_login_counter
  #   if session[:login_counter].nil?
  #     return 0
  #   end
  #   return session[:login_counter] 
  # end

  # def get_login_time
  #   if session[:login_time].nil?
  #     return 0
  #   end
  #   return session[:login_time] 
  # end
  
  def serialize_options(resource)
    methods = resource_class.authentication_keys.dup
    methods = methods.keys if methods.is_a?(Hash)
    methods << :password if resource.respond_to?(:password)
    { :methods => methods, :only => [:password] }
  end

  def auth_options
    { :scope => resource_name, :recall => "#{controller_path}#new" }
  end

  def render_create_success
      p "success login"
      render json: {
        data: resource_data(resource_json: @resource.token_validation_response)
      }
    end

    def render_create_error_not_confirmed
      p "not confirmed"
        
      render json: {
        success: false,
        errors: [ I18n.t("devise_token_auth.sessions.not_confirmed", email: @resource.email) ]
      }, status: 401
    end

    def render_create_error_bad_credentials
        p "bad credentials"
      render json: {
        errors: [I18n.t("devise_token_auth.sessions.bad_credentials")]
      }, status: 401
    end

end

