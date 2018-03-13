require 'test_helper'
 

class UsersControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers
  
  def setup
    @user1 = users(:user1)
    # @user2 = users(:user2)
    # @user4 = users(:user4)
    @admin_user = users(:admin_user)
    @school_administrator = users(:school_administrator)
  end

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

  test 'should return true  message if user not exists' do
    get :user_exist, {params: {email: "a.hossam.201000@gmail.com"}}
    resp =  JSON.parse response.body
    assert_equal resp, {}
  end

  test 'should update completion_wizard in user' do
    user = users(:user1)
    request.headers.merge! user.create_new_auth_token
    sign_in user

    #post '/en/users/1/update_completion_wizard'
    post :update_completion_wizard, {params: {id: 1, completion_wizard: {intro_watched: true}}}
    get :get_current_user
    user = (JSON.parse response.body)["user"]
    assert_equal (JSON.parse user)["completion_wizard"], {"intro_watched" => 'true'}
  end

  test 'alter_pref should update discussion_pref of user' do
    user = users(:user4)
    request.headers.merge! user.create_new_auth_token
    assert_changes 'User.find(4).discussion_pref', from:1, to: 0 do
      post :alter_pref, {params: {privacy: 0}}
    end
  end

  test 'should get_subdomains for school_administrator' do
    user = users(:school_administrator)
    request.headers.merge! user.create_new_auth_token
    sign_in user
    get :get_subdomains, {params: {id: user.id}}
    resp =  JSON.parse response.body
    assert_response :success
    assert_equal resp["subdomains"], ["edu.eg.com"]    
  end

  test 'should get_subdomains for admin_user' do
    user = users(:admin_user)
    request.headers.merge! user.create_new_auth_token
    sign_in user
    get :get_subdomains, {params: {id: user.id}}
    resp =  JSON.parse response.body
    assert_response :success
    assert_equal resp["subdomains"], []    
  end

  test 'should get_subdomains for school_administrator_eg' do
    user = users(:school_administrator_eg)
    request.headers.merge! user.create_new_auth_token
    sign_in user
    get :get_subdomains, {params: {id: user.id}}
    resp =  JSON.parse response.body
    assert_response :success
    assert_equal resp["subdomains"].sort , ["eu.eg", "edu.eg.com"].sort
  end

  test 'should get_welcome_message for school_administrator_eg' do
    user = users(:school_administrator_eg)
    request.headers.merge! user.create_new_auth_token
    sign_in user
    get :get_welcome_message, {params: {id: user.id}}
    resp =  JSON.parse response.body
    assert_response :success
    assert_equal resp["welcome_message"], ""
    assert_equal resp["domain"], '.eg'
  end

  test 'should get_welcome_message for eg_domain_user_1' do
    user = users(:eg_domain_user_1)
    request.headers.merge! user.create_new_auth_token
    sign_in user
    get :get_welcome_message, {params: {id: user.id}}
    resp =  JSON.parse response.body
    assert_response :success
    assert_equal resp["welcome_message"], ""
  end

  test 'should get_welcome_message for user3' do
    user = users(:user3)
    request.headers.merge! user.create_new_auth_token
    sign_in user
    get :get_welcome_message, {params: {id: user.id}}
    resp =  JSON.parse response.body
    assert_response :success
    assert_equal resp, {}
  end

  test 'should submit_welcome_message for school_administrator_eg' do
    user = users(:school_administrator_eg)
    request.headers.merge! user.create_new_auth_token
    sign_in user
    post :submit_welcome_message, {params: {id: user.id, welcome_message: 'welcome_message'}}
    resp =  JSON.parse response.body
    assert_response :success
    assert_equal resp["organization"]["welcome_message"], 'welcome_message'
    assert_equal resp["organization"]["domain"], '.eg'
  end

end
