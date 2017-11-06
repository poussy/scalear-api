require 'test_helper'

class AnnouncementsControllerTest < ActionDispatch::IntegrationTest 
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)

		@course1 = courses(:course1)
		@course2 = courses(:course2)

		@announcement1 = announcements(:announcement1)
		@announcement2 = announcements(:announcement2)
	end

	test "Validate abilities for user1" do
		ability1 = Ability.new(@user1)
		assert ability1.can?(:create, Announcement)
		assert ability1.can?(:destroy, @announcement1)
		assert ability1.cannot?(:destroy, @announcement2)
		assert ability1.cannot?(:index, @announcement2)
	end

	test "Validate abilities for user2" do
		ability2 = Ability.new(@user2)
		assert ability2.can?(:create, Announcement)

		assert ability2.cannot?(:destroy, @announcement1)
		assert ability2.can?(:destroy, @announcement2)

		assert ability2.can?(:teachers, @announcement2)

		@course1.add_professor(@user2 , false)
		assert ability2.can?(:destroy, @announcement1)
		assert ability2.can?(:destroy, @announcement2)
	end

	test 'validate index method for teacher' do
		url = '/en/courses/'+ @course1.id.to_s+'/announcements/'
		get url, headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp.count , 1
	end

	test 'validate destroy method for teacher' do
		url = '/en/courses/'+ @course1.id.to_s+'/announcements/'+ @announcement1.id.to_s
		delete url, headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'] , "Announcement was successfully deleted."

		url = '/en/courses/'+ @course1.id.to_s+'/announcements/'+ @announcement2.id.to_s
		delete url, headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors'][0] , "You are not authorized to see requested page"
	end

	test 'validate create method for teacher ' do
		assert_equal @course1.reload.announcements.count , 1
		url = '/en/courses/'+ @course1.id.to_s+'/announcements/'
		post url, params:{announcement: {announcement: "aa", course_id: @course1.id.to_s }} ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'] , "Announcement was successfully created."
		assert_equal @course1.reload.announcements.count , 2
	end
	test 'validate create method for teacher with empty announcement' do
		url = '/en/courses/'+ @course1.id.to_s+'/announcements/'
		post url, params:{announcement: {announcement: "", course_id: @course1.id.to_s }} ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors']['announcement'][0] , "can't be blank"
	end

	test 'validate update method for teacher ' do
		assert_equal @course1.reload.announcements.count , 1
		url = '/en/courses/'+ @course1.id.to_s+'/announcements/'+ @announcement1.id.to_s
		put url, params:{announcement: {announcement: "aa" }} ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'] , "Announcement was successfully updated."
		assert_equal @announcement1.reload.announcement , 'aa'
	end
	test 'validate update method empty announcement' do
		assert_equal @course1.reload.announcements.count , 1
		url = '/en/courses/'+ @course1.id.to_s+'/announcements/'+ @announcement1.id.to_s
		put url, params:{announcement: {announcement: " " }} ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors']['announcement'][0] , "can't be blank"
		assert_equal @announcement1.reload.announcement , 'announcement'
	end

	test 'validate show method for teacher ' do
		assert_equal @course1.reload.announcements.count , 1
		url = '/en/courses/'+ @course1.id.to_s+'/announcements/'+ @announcement1.id.to_s
		get url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['id'] , @announcement1.id
		assert_equal resp['course_id'] , @course1.id
	end

end