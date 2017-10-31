class Devise::RegistrationsController < DeviseTokenAuth::RegistrationsController


def validate_account_update_params
 params.permit(:user, :registratino)
end


end
