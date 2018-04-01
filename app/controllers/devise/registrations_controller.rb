class Devise::RegistrationsController < DeviseTokenAuth::RegistrationsController
  before_action :set_user_by_token

  def create
    
    if params[:email] && ScalearApi::Application.config.domain_account_block.select{|t| params[:email].include?(t)}.size>0 #blocked domains
      render json: {:errors => {:email => [I18n.t("can_not_use_domain")] , :school_provider=> 'true'}} ,:status => :unprocessable_entity
    ##check if a pseudoanonimised user has same email
    elsif !User.get_anonymised_user(sign_up_params[:email]).nil?
      render json: {:errors => {:email => ["has already been taken"]}} ,:status => :unprocessable_entity
    else #
      @resource            = resource_class.new(sign_up_params)
      @resource.provider   = "email"

      # honor devise configuration for case_insensitive_keys
      if resource_class.case_insensitive_keys.include?(:email)
        @resource.email = sign_up_params[:email].try :downcase
      else
        @resource.email = sign_up_params[:email]
      end

      # give redirect value from params priority
      @redirect_url = params[:confirm_success_url]

      # fall back to default value if provided
      @redirect_url ||= DeviseTokenAuth.default_confirm_success_url

      # success redirect url is required
      if resource_class.devise_modules.include?(:confirmable) && !@redirect_url
        return render_create_error_missing_confirm_success_url
      end

      # if whitelist is set, validate redirect_url against whitelist
      if DeviseTokenAuth.redirect_whitelist
        unless DeviseTokenAuth::Url.whitelisted?(@redirect_url)
          return render_create_error_redirect_url_not_allowed
        end
      end

      begin
        # override email confirmation, must be sent manually from ctrl
        resource_class.set_callback("create", :after, :send_on_create_confirmation_instructions)
        resource_class.skip_callback("create", :after, :send_on_create_confirmation_instructions)
        if @resource.respond_to? :skip_confirmation_notification!
          # Fix duplicate e-mails by disabling Devise confirmation e-mail
          @resource.skip_confirmation_notification!
        end
        if @resource.save
          yield @resource if block_given?

          unless @resource.confirmed?
            # user will require email authentication
            @resource.send_confirmation_instructions({
              client_config: params[:config_name],
              redirect_url: @redirect_url
            })

          else
            # email auth has been bypassed, authenticate user
            @client_id = SecureRandom.urlsafe_base64(nil, false)
            @token     = SecureRandom.urlsafe_base64(nil, false)

            @resource.tokens[@client_id] = {
              token: BCrypt::Password.create(@token),
              expiry: (Time.now + @resource.token_lifespan).to_i
            }

            @resource.save!

            update_auth_header
          end
          render_create_success
        else
          clean_up_passwords @resource
          render_create_error
        end
      rescue ActiveRecord::RecordNotUnique
        clean_up_passwords @resource
        render_create_error_email_already_exists
      end
    end
  
    
  end

  def update 
    super 
  end

  def validate_account_update_params
   params.permit(:user, :registratino)
  end

  private 

    def resource_update_method
      if account_update_params[:saml]
        "update_attributes"
      elsif DeviseTokenAuth.check_current_password_before_update == :attributes
        "update_with_password"
      elsif DeviseTokenAuth.check_current_password_before_update == :password && account_update_params.has_key?(:password)
        "update_with_password"
      elsif account_update_params.has_key?(:current_password)
        "update_with_password"
      else
        "update_attributes"
      end
    end

    def render_update_success
      if account_update_params["password"] != nil
        render json: {:password_confrimation => true}
        UserMailer.password_changed_email(current_user, I18n.locale).deliver
      else
        render json: {
          status: 'success',
          data:   resource_data
        }
      end
    end

end
