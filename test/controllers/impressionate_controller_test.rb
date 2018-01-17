require 'test_helper'

class ImpressionateControllerTest < ActionDispatch::IntegrationTest
  def setup
    ## teacher in course 3
		@user3 = users(:user3)
		@user3.roles << Role.find(1)
		@course3 = courses(:course3)
		@course3.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)

  end
  
  test "should create new user with student role" do
    assert_difference 'User.count' do
      post "/en/impressionate",params:{course_id:3},headers: @user3.create_new_auth_token
    end

    assert_equal User.last["name"], "preview"
    assert_equal User.last["email"], "okasha_preview@scalable-learning.com"
    assert_equal User.last.roles.map{|role| role.id},[1,2,6]

    assert_not decode_json_response_body["token"].nil?
    
  end

  test "should not create user if user is already preview" do
    User.find(3).roles<<Role.find(6)
    #no change
    assert_difference 'User.count', 0 do
      post "/en/impressionate",params:{course_id:3},headers: @user3.create_new_auth_token
    end
    #same user
    assert_equal User.find(3)["name"], "ahmed"
    assert_equal User.find(3)["email"], "okasha@gmail.com"

    assert_not decode_json_response_body["token"].nil?
    
  end

  test "destroy should delete preview user and respond with old user" do
    assert_difference 'User.count', -1 do
      Delayed::Worker.delay_jobs = false
      delete "/en/impressionate", params:{old_user_id:3, new_user_id:4}, headers:@user3.create_new_auth_token
    end

    assert_not User.exists?(id:4)

    assert_not decode_json_response_body["token"].nil?
    
  end
  
end
