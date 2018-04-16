class Devise::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
    def create
        resource = User.where(email:params[:email])[0]
        if resource.blank?
            render json: {errors: {email:["User doesn't exist"]}}, :status => :unprocessable_entity
        else
            resource.send_confirmation_instructions({
                client_config: params[:config_name],
                redirect_url: params[:confirm_success_url]
              })
        end
    end

    def show
        @resource = resource_class.confirm_by_token(params[:confirmation_token])
       
        if @resource && @resource.id
          # create client id
          client_id  = SecureRandom.urlsafe_base64(nil, false)
          token      = SecureRandom.urlsafe_base64(nil, false)
          token_hash = BCrypt::Password.create(token)
          expiry     = (Time.now + DeviseTokenAuth.token_lifespan).to_i
  
          @resource.tokens[client_id] = {
            token:  token_hash,
            expiry: expiry
          }
  
          sign_in(@resource)
          if @resource.errors.include?(:email) && User.find_by_confirmation_token(params[:confirmation_token])
            redirect_header_options = {account_confirmation_success: false}
          else
            redirect_header_options = {account_confirmation_success: true}
          end

          @resource.save!
          
          
          redirect_headers = build_redirect_headers(token,
                                                    client_id,
                                                    redirect_header_options)
          redirect_headers['uid'] = @resource['uid']
          redirect_url = "#{params[:redirect_url]}?#{redirect_headers.to_query}"
        else
            redirect_url = "#{params[:redirect_url]}?#{{account_confirmation_success: false}.to_query}"
        end
        redirect_to(redirect_url)
    end

    private 

        def build_redirect_headers(access_token, client, redirect_header_options = {})
        {
            DeviseTokenAuth.headers_names[:"access-token"] => access_token,
            DeviseTokenAuth.headers_names[:"client"] => client,
            :config => params[:config],

            # Legacy parameters which may be removed in a future release.
            # Consider using "client" and "access-token" in client code.
            # See: github.com/lynndylanhurley/devise_token_auth/issues/993
            :client_id => client,
            :token => access_token
        }.merge(redirect_header_options)
        end
end

