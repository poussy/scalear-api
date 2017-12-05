require 'test_helper'

class DiscussionsControllerTest < ActionDispatch::IntegrationTest

	# def create_post
	# def update_post
	# def delete_post
	# def delete_comment
	# def create_comment
	# def vote
	# def flag
	# def vote_comment
	# def flag_comment

	test 'validate index method for Admin' do
		url = '/en/discussion'
		get  url ,headers: @admin_user.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['total'] , 5
	end		

	# test 'validate new method for teacher' do
	# 	url = '/en/courses/new'
	# 	get  url ,headers: @user1.create_new_auth_token 
	# 	resp =  JSON.parse response.body
	# 	assert_equal resp['importing'].count , 1
		
	# 	@course2.add_professor(@user1,false)
	# 	get  url ,headers: @user1.create_new_auth_token 
	# 	resp =  JSON.parse response.body
	# 	assert_equal resp['importing'].count , 2
	# end	

end