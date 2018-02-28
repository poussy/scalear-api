class Devise::PasswordsController < DeviseTokenAuth::PasswordsController
    before_action :set_user_by_token, :only => [:update]
    skip_after_action :update_auth_header, :only => [:create, :edit]
  # POST /resource/password
  def create
    
      unless resource_params[:email]
        return render_create_error_missing_email
      end

      # give redirect value from params priority
      @redirect_url = params[:redirect_url]

      # fall back to default value if provided
      @redirect_url ||= DeviseTokenAuth.default_password_reset_url

      unless @redirect_url
        return render_create_error_missing_redirect_url
      end

      # if whitelist is set, validate redirect_url against whitelist
      if DeviseTokenAuth.redirect_whitelist
        unless DeviseTokenAuth::Url.whitelisted?(@redirect_url)
          return render_create_error_not_allowed_redirect_url
        end
      end

      @email = resource_params[:email].downcase
      @resource = User.find_by_email(@email)
      if @resource.nil?
        ##check if user is anonymised
        encrypted_email = Digest::SHA256.hexdigest (resource_params[:email])
        @resource = User.find_by_encrypted_email(encrypted_email)
      end

      @errors = nil
      @error_status = 400

      if @resource
        yield @resource if block_given?
        @resource.send_reset_password_instructions({
          to: @email,
          email: @email,
          provider: 'email',
          redirect_url: @redirect_url,
          client_config: params[:config_name]
        })

        if @resource.errors.empty?
          return render_create_success
        else
          @errors = @resource.errors
        end
      else
        @errors = [I18n.t("devise_token_auth.passwords.user_not_found", email: @email)]
        @error_status = 404
      end

      if @errors
        return render_create_error
      end
    
  end


#   # PUT /resource/password
  def update
    
    super
    
  end

  def edit
     # if a user is not found, return nil
      @resource = resource_class.with_reset_password_token(
        resource_params[:reset_password_token]
      )

      if @resource
        client_id  = SecureRandom.urlsafe_base64(nil, false)
        token      = SecureRandom.urlsafe_base64(nil, false)
        token_hash = BCrypt::Password.create(token)
        expiry     = (Time.now + 7.days).to_i

        @resource.tokens[client_id] = {
          token:  token_hash,
          expiry: expiry
        }

        # ensure that user is confirmed
        @resource.skip_confirmation! if @resource.devise_modules.include?(:confirmable) && !@resource.confirmed_at

        # allow user to change password once without current_password
        @resource.allow_password_change = true;

        @resource.save!

        yield @resource if block_given?

        redirect_header_options = {reset_password: true}
        redirect_headers = build_redirect_headers(token,
                                                  client_id,
                                                  redirect_header_options)
        
        redirect_headers[:uid]    =  @resource.uid
        redirect_headers[:expiry] =  @resource.tokens[redirect_headers[:client_id]]['expiry']

        # override devise's method in creating the url
        redirect_url = "#{params[:redirect_url]}?#{redirect_headers.to_query}"

        redirect_to(redirect_url)
      else
        render_edit_error
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
