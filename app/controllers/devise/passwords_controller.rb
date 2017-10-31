class Devise::PasswordsController < DeviseTokenAuth::PasswordsController
    before_action :set_user_by_token, :only => [:update]
    skip_after_action :update_auth_header, :only => [:create, :edit]
  # POST /resource/password
  def create
   super
  end


#   # PUT /resource/password
  def update
    
    super
    
  end

  def edit
    
     super
  
  end

end
