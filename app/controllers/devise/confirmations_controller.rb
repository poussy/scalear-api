class Devise::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
    def create
        self.resource = resource_class.send_confirmation_instructions(params)
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
          @resource.save!
  
          redirect_header_options = {account_confirmation_success: true}
          redirect_headers = build_redirect_headers(token,
                                                    client_id,
                                                    redirect_header_options)
          redirect_headers['uid'] = @resource['uid']
          redirect_url = "#{params[:redirect_url]}?#{redirect_headers.to_query}"
          redirect_to(redirect_url)
        else
          raise ActionController::RoutingError.new('Not Found')
        end
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

