# class Devise::PasswordsController < DeviseController
#   prepend_before_filter :require_no_authentication
#   # Render the #edit only if coming from a reset password email link
#   append_before_filter :assert_reset_token_passed, :only => :edit

#   # GET /resource/password/new
#   def new
#     build_resource({})
#     render json: {}
#   end

#   # POST /resource/password
#   def create
#     if resource_params[:email] && !resource_params[:email].empty? && User.exists?(:email => resource_params[:email].downcase) && User.find_by_email(resource_params[:email].downcase).saml
#       render json: {errors: {email: ["Your password is managed through your school or university. Please use the school/university login to access ScalableLearning"]}, saml:true}, :status => 422
#     else
#       self.resource = resource_class.send_reset_password_instructions(resource_params)
#       set_flash_message(:notice, :send_instructions)
#       if successfully_sent?(resource)
#         respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
#       else
#         respond_with(resource)
#       end
#     end
#   end

#   # GET /resource/password/edit?reset_password_token=abcdef
#   def edit
#     self.resource = resource_class.new
#     resource.reset_password_token = params[:reset_password_token]
#   end

#   # PUT /resource/password
#   def update
#     self.resource = resource_class.reset_password_by_token(resource_params)
#     if resource.errors[:reset_password_token].empty?
#       if resource.errors[:password].empty?
#         flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
#         set_flash_message(:notice, flash_message) #if is_navigational_format?
#         sign_in(resource_name, resource)
#         render json: {}
#       else
#         render json: {errors:resource.errors}, status: :unprocessable_entity
#       end
#     else
#       render json: {errors:resource.errors.full_messages}, status: 400
#     end

#   end

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
# end
