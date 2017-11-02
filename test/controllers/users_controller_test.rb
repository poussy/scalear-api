require 'test_helper'
 

class UsersControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers
  test 'user should be able to sign in' do
    user = users(:user1)
    
    request.headers.merge! user.create_new_auth_token
    sign_in user
    
    assert_response :success

  end

  test 'should return current user if user is signed in' do
    user = users(:user1)
    

    request.headers.merge! user.create_new_auth_token
    sign_in user

    get :get_current_user

    resp =  JSON.parse response.body

    assert_equal resp["signed_in"], true

    user =JSON.parse resp["user"]

    assert user["email"], "a.hossam.2010@gmail.com"
    
  end

  test 'should return error message if user exists' do
    
    get :user_exist, {params: {email: "a.hossam.2010@gmail.com"}}

    assert_equal (JSON.parse response.body)["errors"][0], "Email already exist, please try to login"
    
  end

  test 'should update completion_wizard in user' do

    user = users(:user1)
    
    request.headers.merge! user.create_new_auth_token
    sign_in user

    #post '/en/users/1/update_completion_wizard'
    post :update_completion_wizard, {params: {id: 1, completion_wizard: {intro_watched: true}}}

    get :get_current_user

    user = (JSON.parse response.body)["user"]

    assert_equal (JSON.parse user)["completion_wizard"], {"intro_watched" => true}


  end
  




end
