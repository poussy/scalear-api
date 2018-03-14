class Devise::RegistrationsController < DeviseTokenAuth::RegistrationsController
  before_action :set_user_by_token

  def create
    
    if params[:email] && ScalearApi::Application.config.domain_account_block.select{|t| params[:email].include?(t)}.size>0
      render json: {:errors => {:email => [I18n.t("can_not_use_domain")] , :school_provider=> 'true'}} ,:status => :unprocessable_entity
    ##check if a pseudoanonimised user has same email
    elsif !User.get_anonymised_user(sign_up_params[:email]).nil?
      render json: {:errors => {:email => ["has already been taken"]}} ,:status => :unprocessable_entity
    else
      super
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
