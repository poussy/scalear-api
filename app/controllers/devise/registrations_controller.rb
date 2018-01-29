class Devise::RegistrationsController < DeviseTokenAuth::RegistrationsController
    before_action :set_user_by_token

  def create
    if params[:email] && ScalearApi::Application.config.domain_account_block.select{|t| params[:email].include?(t)}.size>0
      render json: {:errors => {:email => [I18n.t("can_not_use_domain")] , :school_provider=> 'true'}} ,:status => :unprocessable_entity
    else
      super
    end
  end

end
