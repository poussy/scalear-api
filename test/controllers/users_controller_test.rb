require 'test_helper'
 

class UsersControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers
  test 'user should be able to sign in' do
    user = users(:user1)
    
    request.headers.merge! user.create_new_auth_token
    sign_in user
    
    assert_response :success

  end

  test 'get current user returns current user if user is signed in' do
    user = users(:user1)
    

    request.headers.merge! user.create_new_auth_token
    sign_in user

    get :get_current_user

    resp =  ActiveSupport::JSON.decode response.body

    assert_equal resp["signed_in"], true

    user = ActiveSupport::JSON.decode resp["user"]

    assert user["email"], "a.hossam.2010@gmail.com"
    
  end
end
