class Devise::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
    def create
        self.resource = resource_class.send_confirmation_instructions(params)
       
        if !successfully_sent?(resource)
            resource.send_confirmation_instructions
        else
            respond_with(resource)
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
            redirect_header_options = {account_confirmation_success: "confirmed"}
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
            redirect_url = "#{params[:redirect_url]}?#{{account_confirmation_success: "invalid"}.to_query}"
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

