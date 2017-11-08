require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
	
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)
		@invitated_user = users(:invitated_user)

		@course1 = courses(:course1)
		@course2 = courses(:course2)

		@invitation1 = invitations(:invitation1)
	end

	test 'validate notifications method for teacher ' do
		url = '/en/home/notifications'
		get url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['invitations'] , {}
	end
	test 'validate notifications method for invited teacher ' do
		url = '/en/home/notifications'
		get url ,headers: @invitated_user.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['invitations'].count , 1
	end	
	
	test 'validate accept_course method for invitated_user' do
		url = '/en/home/accept_course'
		post url ,params:  {"invitation"=> @invitation1.id.to_s , "home"=>{"invitation"=>@invitation1.id.to_s}}  ,headers: @invitated_user.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'] , "You have accepted the invitation to course name"
		assert_equal resp['invitations'] , 0
	end
	test 'validate accept_course method for teacher Wrong Credentails' do
		url = '/en/home/accept_course'
		post url ,params:  {"invitation"=> @invitation1.id.to_s , "home"=>{"invitation"=>@invitation1.id.to_s}}  ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors'] , "Wrong Credentials"
	end
	
	test 'validate reject_course method for invitated_user' do
		url = '/en/home/reject_course'
		post url ,params:  {"invitation"=> @invitation1.id.to_s , "home"=>{"invitation"=>@invitation1.id.to_s}}  ,headers: @invitated_user.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'] , "You have rejected the invitation to course name"
		assert_equal resp['invitations'] , 0
	end
	test 'validate reject_course method for teacher Wrong Credentails' do
		url = '/en/home/reject_course'
		post url ,params:  {"invitation"=> @invitation1.id.to_s , "home"=>{"invitation"=>@invitation1.id.to_s}}  ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors'] , "Wrong Credentials"
	end

end
