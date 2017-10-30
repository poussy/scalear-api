class Devise::PasswordsController < DeviseTokenAuth::PasswordsController
    before_action :set_user_by_token, :only => [:update]
    skip_after_action :update_auth_header, :only => [:create, :edit]
  # POST /resource/password
  def create
   super
  end

#   # GET /resource/password/edit?reset_password_token=abcdef
#   def edit
#     self.resource = resource_class.new
#     resource.reset_password_token = params[:reset_password_token]
#   end

#   # PUT /resource/password
  def update
    
    super
    
  end

  def edit
    
     super
  
  end

# # include Devise::Models::Recoverable

# # Devise::Models::Recoverable.module_eval do
# #       def reset_password!(new_password, new_password_confirmation)
# #         puts "Reseting password from my own function"
# #         self.password = new_password
# #         self.password_confirmation = new_password_confirmation
# #         save(:valid => false)
# #         clear_reset_password_token
# #         after_password_reset
# #       end
# # end

#   protected

#     # The path used after sending reset password instructions
#     def after_sending_reset_password_instructions_path_for(resource_name)
#       new_session_path(resource_name)
#     end

#     # Check if a reset_password_token is provided in the request
#     def assert_reset_token_passed
#       if params[:reset_password_token].blank?
#         set_flash_message(:error, :no_token)
#         redirect_to new_session_path(resource_name)
#       end
#     end
end
