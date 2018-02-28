class Devise::RegistrationsController < DeviseTokenAuth::RegistrationsController
  before_action :set_user_by_token

  def create
    
    encrypted_email = Digest::SHA256.hexdigest (sign_up_params[:email])
    
    if params[:email] && ScalearApi::Application.config.domain_account_block.select{|t| params[:email].include?(t)}.size>0
      render json: {:errors => {:email => [I18n.t("can_not_use_domain")] , :school_provider=> 'true'}} ,:status => :unprocessable_entity
    ##check if a pseudoanonimised user has same email
    elsif !User.find_by_encrypted_email(encrypted_email).nil?
      render json: {:errors => {:email => ["has already been taken"]}} ,:status => :unprocessable_entity
    else
      super
    end
  end

  def validate_account_update_params
   params.permit(:user, :registratino)
  end

end
