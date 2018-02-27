class Devise::SessionsController < DeviseTokenAuth::SessionsController
  
    def render_create_error_bad_credentials

        ### in case user is pseudoanonymised ###
        email = resource_params[:email]
        encrypted_email = Digest::SHA256.hexdigest (email)

        user = User.find_by_encrypted_email(encrypted_email)
        if !user.nil? &&  user.valid_password?(resource_params[:password])
            
            user.email = resource_params[:email]
            ## use user's email to decrypt information
            key   = ActiveSupport::KeyGenerator.new(email).generate_key(ENV['gdpr_salt'],32)
            crypt = ActiveSupport::MessageEncryptor.new(key)
            
            user.name =crypt.decrypt_and_verify(user.encrypted_data['name'])
            user.last_name = crypt.decrypt_and_verify(user.encrypted_data['last_name'])
            user.screen_name =crypt.decrypt_and_verify(user.encrypted_data['screen_name'])
            user.university =crypt.decrypt_and_verify(user.encrypted_data['university'])
            user.encrypted_email = nil
            user.encrypted_data = nil
            user.skip_confirmation!
            user.skip_reconfirmation!
            
            # create token and sign in user
            @resource = user
            
            @client_id = SecureRandom.urlsafe_base64(nil, false)
            @token     = SecureRandom.urlsafe_base64(nil, false)
            @resource.tokens[@client_id] = {
            token: BCrypt::Password.create(@token),
            expiry: (Time.now + DeviseTokenAuth.token_lifespan).to_i
            }
            @resource.save

            render_create_success
        else

            render json: {
            errors: [I18n.t("devise_token_auth.sessions.bad_credentials")]
            }, status: 401
        end
    end
end

