class Devise::SessionsController < DeviseTokenAuth::SessionsController
  
    def render_create_error_bad_credentials

        ### in case user is pseudoanonymised ###
        email = resource_params[:email]
        user = User.get_anonymised_user(email)
        if !user.nil? &&  user.valid_password?(resource_params[:password])
            
            
            # create token and sign in user
            @resource = user.deanonymise(email)
            @resource.generate_token(DeviseTokenAuth.token_lifespan)
           
            if @resource.save
                pp @resource
                render_create_success
            else 
                render json: @resource.errors
            end
        else

            render json: {
            errors: [I18n.t("devise_token_auth.sessions.bad_credentials")]
            }, status: 401
        end
    end

    
end

