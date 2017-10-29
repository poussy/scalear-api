class Devise::RegistrationsController < DeviseTokenAuth::RegistrationsController
#   # prepend_before_filter :require_no_authentication, :only => [ :new, :create, :cancel ]
#   # prepend_before_filter :authenticate_scope!, :only => [:edit, :update, :destroy]

#   # GET /resource/sign_up
#   def new
#     resource = build_resource({})
#     respond_with resource
#   end

#   # POST /resource
#   # def create
#   #   p '---------------------------'
#   #   p 'registrations controller create method'
#   #   # if params[:user][:email] && OnlineEdu::Application.config.domain_account_block.select{|t| params[:user][:email].include?(t)}.size>0
#   #   #   render json: {:errors => {:email => [t("can_not_use_domain")] , :school_provider=> 'true'}} ,:status => :unprocessable_entity
#   #   # else
#   #     build_resource
#   #     # resource.roles << Role.find(1)
#   #     # resource.roles << Role.find(2)
#   #     if resource.save
#   #       if resource.active_for_authentication?
#   #         set_flash_message :notice, :signed_up #if is_navigational_format?
#   #         sign_in(resource_name, resource)
#   #         respond_with resource, :location => after_sign_up_path_for(resource)
#   #       else
#   #         set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" #if is_navigational_format?
#   #         expire_session_data_after_sign_in!
#   #         respond_with resource, :location => after_inactive_sign_up_path_for(resource)
#   #       end
#   #     else
#   #       clean_up_passwords resource
#   #       respond_with resource
#   #     end
#   #   # end
#   # end

#   # GET /resource/edit
#   def edit
#     # render :edit
#     render :json =>{}
#   end

#   # PUT /resource
#   # We need to use a copy of the resource because we don't want to change
#   # the current user in place.
  def update
      p'--------------------------------------------'
      p params 
      super
    # self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    # p resource_params
    # if ( resource_params[:saml] && resource.update_without_password(resource_params) ) || ( !resource_params[:saml] && resource.update_with_password(resource_params) )
    #   #if is_navigational_format?
    #     if resource.respond_to?(:pending_reconfirmation?) && resource.pending_reconfirmation?
    #       flash_key = :update_needs_confirmation
    #     end
    #     set_flash_message :notice, flash_key || :updated
    #   #end
    #   sign_in resource_name, resource, :bypass => true
    #     if resource_params["password"] != nil
    #       render json: {:password_confrimation => true}
    #       UserMailer.password_changed_email(current_user, I18n.locale).deliver

    #     else
    #       respond_with resource, :location => after_update_path_for(resource)
    #     end

    # else
    #   clean_up_passwords resource
    #   # respond_with resource
    #   if resource.errors.messages.has_key?(:current_password)
    #     resource.errors.messages[:current_password] = [t("invalid_password")]
    #   end
    #   render json: {:errors => resource.errors}, :status => :unprocessable_entity
    # end
  end

#   # DELETE /resource
#   def destroy
#     if (current_user.saml) || ( !current_user.saml && current_user.valid_password?(params[:password]) )
#       resource.destroy
#       Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
#       set_flash_message :notice, :destroyed #if is_navigational_format?
#       respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
#     else
#       render :json => {:errors => [t("invalid_password")]}, :status => 422
#     end
#   end

#   # GET /resource/cancel
#   # Forces the session data which is usually expired after sign
#   # in to be expired now. This is useful if the user wants to
#   # cancel oauth signing in/up in the middle of the process,
#   # removing all OAuth session data.
#   def cancel
#     expire_session_data_after_sign_in!
#     redirect_to new_registration_path(resource_name)
#   end

#   protected

#   # Build a devise resource passing in the session. Useful to move
#   # temporary session data to the newly created user.
#   # def build_resource(hash=nil)
#   #   hash ||= resource_params || {}
#   #   self.resource = resource_class.new_with_session(hash, session)
#   # end

#   # The path used after sign up. You need to overwrite this method
#   # in your own RegistrationsController.
#   def after_sign_up_path_for(resource)
#     after_sign_in_path_for(resource)
#   end

#   # The path used after sign up for inactive accounts. You need to overwrite
#   # this method in your own RegistrationsController.
#   def after_inactive_sign_up_path_for(resource)
#     respond_to?(:root_path) ? root_path : "/"
#   end

#   # The default url to be used after updating a resource. You need to overwrite
#   # this method in your own RegistrationsController.
#   def after_update_path_for(resource)
#     signed_in_root_path(resource)
#   end

#   # Authenticates the current scope and gets the current resource from the session.
#   def authenticate_scope!
#     send(:"authenticate_#{resource_name}!", :force => true)
#     self.resource = send(:"current_#{resource_name}")
#   end

#   def sign_up_params
#       params.permit(:email, :password, :last_name, :registration)
#   end

def validate_account_update_params
 params.permit(:user, :registratino)
end


end
