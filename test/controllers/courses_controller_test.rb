require 'test_helper'

class CoursesControllerTest <  ActionController::TestCase
	include Devise::Test::ControllerHelpers
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)

		@course1 = courses(:course1)
		@course2 = courses(:course2)

		@course_domain1 = course_domains(:course_domain_1)

		@group2 = groups(:group2)
	end

	test "Validate abilities for user1" do
		ability1 = Ability.new(@user1)
		assert ability1.can?(:create, Course)
		assert ability1.can?(:destroy, @course1)
		assert ability1.cannot?(:destroy, @course2)
		assert ability1.can?(:teachers, @course1)
		assert ability1.cannot?(:getCourse, @course1)
	end

	test "Validate abilities for user2" do
		ability2 = Ability.new(@user2)
		assert ability2.can?(:create, Course)

		assert ability2.cannot?(:destroy, @course1)
		assert ability2.can?(:destroy, @course2)

		assert ability2.can?(:teachers, @course2)
		assert ability2.cannot?(:getCourse, @course2)

		@course1.add_professor(@user2 , false)
		assert ability2.can?(:destroy, @course1)
		assert ability2.can?(:destroy, @course2)
	end

	test 'user should be able to sign in' do
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		assert_response :success
	end

	test 'validate index method for teacher' do
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :index
		resp =  JSON.parse response.body
		assert_equal resp['total'] , 1
		
		@course2.add_professor(@user1,false)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :index
		resp =  JSON.parse response.body
		assert_equal resp['total'] , 2
	end

	test 'validate index method for Admin' do
		admin_user = users(:admin_user)
		request.headers.merge! admin_user.create_new_auth_token
		sign_in admin_user
		get :index
		resp =  JSON.parse response.body
		assert_equal resp['total'] , 5
	end		

	test 'validate new method for teacher' do
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :new
		resp =  JSON.parse response.body
		assert_equal resp['importing'].count , 1
		
		@course2.add_professor(@user1,false)
		get :new
		resp =  JSON.parse response.body
		assert_equal resp['importing'].count , 2
	end

	test 'validate new method for Admin' do
		admin_user = users(:admin_user)
		request.headers.merge! admin_user.create_new_auth_token
		sign_in admin_user
		get :new
		resp =  JSON.parse response.body
		assert_equal resp['importing'].count , 5
	end		

	test 'validate Teachers method for user1 for course1' do
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :teachers , { params: {id: @course1.id} }
		resp =  JSON.parse response.body
		assert_equal resp['data'].count , 1
		assert_equal resp['data'][0]['owner'] , true
		assert_equal resp['data'][0]['email'] , 'a.hossam.2010@gmail.com'
	end
	test 'validate Teachers method for user1 for course1 count = 2' do		
		@course1.add_professor(@user2,false)
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :teachers , { params: {id: @course1.id} }
		resp =  JSON.parse response.body
		assert_equal resp['data'].count , 2
	end

	test 'validate Teachers method for user1 for course2s' do
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :teachers , { params: {id: @course2.id} }
		resp =  JSON.parse response.body
		assert_response 403
	end


	test 'validate get_selected_subdomains method for user1 for course1' do
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :get_selected_subdomains , { params: {id: @course1.id} }
		resp =  JSON.parse response.body
		assert_equal resp['subdomains'].count , 1
		assert_equal resp['selected_domain']['gmail.com'] , true
	end
	test 'validate get_selected_subdomains method for user1 for course1 after deleteing @course_domain1' do		
		@course_domain1.destroy
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :get_selected_subdomains , { params: {id: @course1.id} }
		resp =  JSON.parse response.body
		assert_equal resp['subdomains'].count , 1
		assert_equal resp['selected_domain']['All'] , true
	end
	test 'validate get_selected_subdomains method after cahnging email to un.se' do		
		@course1.add_professor(@user2 , false)		
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :get_selected_subdomains , { params: {id: @course1.id} }
		resp =  JSON.parse response.body
		assert_equal resp['subdomains'].count , 2
		assert_equal resp['selected_domain']['gmail.com'] , true
	end



	test 'validate validate_course_angular method ' do		
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :validate_course_angular , { params: {id: @course1.id , course: { name:'toto' } } }
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal resp['nothing'] , true
	end
	test 'validate validate_course_angular method and respone 422' do		
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :validate_course_angular , { params: {id: @course1.id , course: { start_date:DateTime.now + 3.months } } }
		assert_response 422
		resp =  JSON.parse response.body
		assert_equal resp['errors'].count , 1
		assert_equal resp['errors'][0] , "End date courses.errors.end_date_pass"
	end

	test 'validate update method ' do		
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :update , { params: {id: @course1.id , course: {"course"=>{"user_id"=>1, "short_name"=>"a", "name"=>"aa", "time_zone"=>"UTC", "start_date"=>"2017-11-01", "end_date"=>"2018-01-10", "disable_registration"=>nil, "description"=>"", "prerequisites"=>"", "discussion_link"=>"", "image_url"=>nil, "importing"=>false, "parent_id"=>nil}, "id"=>"1"} } }
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal resp['notice'][0] , "controller_msg.course_successfully_updated"
	end

	test 'validate update method and respone 422' do		
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :update , { params: {id: @course1.id , course: { start_date:DateTime.now + 3.months } } }
		assert_response 422
		resp =  JSON.parse response.body
		assert_equal resp['errors'].count , 1
		assert_equal resp['errors']['end_date'][0] , "courses.errors.end_date_pass"
	end

	test 'validate course_editor_angular method ' do		
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :course_editor_angular , { params: {id: @course1.id} }
		resp =  JSON.parse response.body
		assert_equal resp['course']['duration'] , 5
		assert_equal resp['groups'].count , 1
	end

	test 'validate course_editor_angular method after added group2 to course1' do		
		@group2.course  = @course1
		@group2.save
		user = users(:user1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		get :course_editor_angular , { params: {id: @course1.id} }
		resp =  JSON.parse response.body
		assert_equal resp['course']['duration'] , 5
		assert_equal resp['groups'].count , 2
	end

	test "user should be able to import course" do
		user = users(:user3)
		user.roles << Role.find(1)
		request.headers.merge! user.create_new_auth_token
		sign_in user
		initial_course_count = Course.count
		
		assert_equal Course.count, initial_course_count
		assert Course.find_by_name("import_test").nil?
		## to invoke delayed jobs synchrously
		Delayed::Worker.delay_jobs = false
		post :create , { params: {
					course:{time_zone: "UTC",start_date:"2017-11-08T12:25:14.079Z",end_date:"2018-01-17T10:25:14.079Z",short_name:"test",name:"import_test"},
					import:3,
					subdomains:{All:true},
					email_discussion:false
				}}
		
		## new course is created
		assert_equal Course.count, initial_course_count + 1
		assert Course.find_by_name("import_test").present?
		
		course_from = Course.find(3)
		new_course =  Course.last
		# compare new and imported groups
		new_course.groups.each_with_index do |new_group, i|
			assert  course_from.groups[i].name == new_group.name
			# compare new and imported lectures
			lectures_from = course_from.groups[i].lectures
			new_group.lectures.each_with_index do |new_lecture, j|
				assert lectures_from[j].name == new_lecture.name
				## difference between courses start_date is 65 days
				assert_equal lectures_from[j].appearance_time.to_date + 65.days, new_lecture.appearance_time.to_date
			end
			# compare quizzes
			quizzes_from = course_from.groups[i].quizzes
			new_group.quizzes.each_with_index do |new_quiz, k|
				assert quizzes_from[k].name == new_quiz.name
			end
			#compare custom_links
			links_from = course_from.groups[i].custom_links
			new_group.custom_links.each_with_index do |new_link, m|
				assert links_from[m].name = new_link.name
			end
			
		end
		
	end

end