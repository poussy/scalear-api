require 'test_helper'

class CoursesControllerTest <  ActionDispatch::IntegrationTest 
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)
		@user4 = users(:user4)
		@admin_user = users(:admin_user)
		@invitated_user = users(:invitated_user)

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

	test 'validate index method for teacher' do
		url = '/en/courses'
		get  url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['total'] , 1
		
		@course2.add_professor(@user1,false)
		get  url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['total'] , 2
	end

	test 'validate index method for Admin' do
		url = '/en/courses'
		get  url ,headers: @admin_user.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['total'] , 5
	end		

	test 'validate new method for teacher' do
		url = '/en/courses/new'
		get  url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['importing'].count , 1
		
		@course2.add_professor(@user1,false)
		get  url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['importing'].count , 2
	end

	test 'validate new method for Admin' do
		url = '/en/courses/new'
		get  url ,headers: @admin_user.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['importing'].count , 5
	end		

	test 'validate Teachers method for user1 for course1' do
		url = '/en/courses/'+ @course1.id.to_s+'/teachers/'
		get  url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['data'].count , 2
		assert_equal resp['data'][0]['owner'] , true
		assert_equal resp['data'][0]['email'] , 'a.hossam.2010@gmail.com'
		## pending invitations student
		assert_equal resp['data'][1]['status'] , 'Pending'
		assert_equal resp['data'][1]['email'] , 'a.hossam.2011@gmail.com'
	end
	
	test 'validate Teachers method for user1 for course1 count = 2' do
		@course1.add_professor(@user2,false)
		url = '/en/courses/'+ @course1.id.to_s+'/teachers/'
		get  url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['data'].count , 3
	end

	test 'validate Teachers method for user1 for course2s' do
		url = '/en/courses/'+ @course2.id.to_s+'/teachers/'
		get  url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_response 403
	end

	test 'validate get_selected_subdomains method for user1 for course1' do
		url = '/en/courses/'+ @course1.id.to_s+'/get_selected_subdomains/'
		get  url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['subdomains'].count , 1
		assert_equal resp['selected_domain']['gmail.com'] , true
	end
	
	test 'validate get_selected_subdomains method for user1 for course1 after deleteing @course_domain1' do	
		@course_domain1.destroy
		url = '/en/courses/'+ @course1.id.to_s+'/get_selected_subdomains/'
		get  url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['subdomains'].count , 1
		assert_equal resp['selected_domain']['All'] , true
	end
	
	test 'validate get_selected_subdomains method after cahnging email to un.se' do	
		@course1.add_professor(@user2 , false)		
		url = '/en/courses/'+ @course1.id.to_s+'/get_selected_subdomains/'
		get  url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['subdomains'].count , 2
		assert_equal resp['selected_domain']['gmail.com'] , true
	end

	test 'validate validate_course_angular method ' do
		url = '/en/courses/'+ @course1.id.to_s+'/validate_course_angular/'
		put  url , params: {course: { name:'toto' } } ,headers: @user1.create_new_auth_token 
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal resp['nothing'] , true
	end
	test 'validate validate_course_angular method and respone 422' do
		url = '/en/courses/'+ @course1.id.to_s+'/validate_course_angular/'
		put  url , params: {course: { start_date:DateTime.now + 3.months } } ,headers: @user1.create_new_auth_token 
		assert_response 422
		resp =  JSON.parse response.body
		assert_equal resp['errors'].count , 1
		assert_equal resp['errors'][0] , "End date must be after the start date"
	end

	test 'validate create method ' do
		assert_equal @user1.reload.subjects_to_teach.count , 1
		url = '/en/courses/'
		post  url , params: {"course"=>{"time_zone"=>"UTC", "start_date"=>"2017-11-07T16:24:19.495Z", "end_date"=>"2018-01-16T14:24:19.495Z", 
			"short_name"=>"aaa", "name"=>"qaaaw"}, "import"=>nil, "subdomains"=>{"All"=>true}, "email_discussion"=>false} ,
			headers: @user1.create_new_auth_token 
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal @user1.reload.subjects_to_teach.count , 2
		assert_equal Course.last.reload.course_domains.count , 0
		assert_equal resp['notice'][0] , "Course was successfully created."
	end

	test 'validate create method with course domain' do
		assert_equal @user1.reload.subjects_to_teach.count , 1
		url = '/en/courses/'
		post  url , params: {"course"=>{"time_zone"=>"UTC", "start_date"=>"2017-11-07T16:24:19.495Z", "end_date"=>"2018-01-16T14:24:19.495Z", 
			"short_name"=>"aaa", "name"=>"qaaaw"}, "import"=>nil, "subdomains"=>{"gmail"=>true}, "email_discussion"=>false} ,
			headers: @user1.create_new_auth_token 
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal @user1.reload.subjects_to_teach.count , 2
		assert_equal Course.last.reload.course_domains.count , 1
		assert_equal resp['notice'][0] , "Course was successfully created."
	end

	test 'validate update method ' do
		url = '/en/courses/'+ @course1.id.to_s+'/'
		put  url , params: {"course"=>{"user_id"=> @user1.id , "short_name"=>"aa", "name"=>"a", "time_zone"=>"UTC", "start_date"=>"2017-11-05", "end_date"=>"2018-01-14", 
			"disable_registration"=>"2018-01-14", "description"=>nil, "prerequisites"=>nil, "discussion_link"=>"", "image_url"=>nil, "importing"=>false, "parent_id"=>nil}, "id"=>"1"} ,
			headers: @user1.create_new_auth_token 
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal resp['notice'][0] , "Course was successfully updated."
	end

	test 'validate update method and respone 422' do
		url = '/en/courses/'+ @course1.id.to_s+'/'
		put  url , params: {course: { start_date:DateTime.now + 3.months } } ,headers: @user1.create_new_auth_token 
		assert_response 422
		resp =  JSON.parse response.body
		assert_equal resp['errors'].count , 1
		assert_equal resp['errors']['end_date'][0] , "must be after the start date"
	end

	test 'validate course_editor_angular method ' do
		url = '/en/courses/'+ @course1.id.to_s+'/course_editor_angular'
		get  url  ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['course']['duration'] , 5
		assert_equal resp['groups'].count , 1
	end

	test 'validate course_editor_angular method after added group2 to course1' do		
		@group2.course  = @course1
		@group2.save
		url = '/en/courses/'+ @course1.id.to_s+'/course_editor_angular'
		get  url  ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['course']['duration'] , 5
		assert_equal resp['groups'].count , 2
	end

	test "should import course" do
		user = users(:user3)
		user.roles << Role.find(1)
		
		initial_course_count = Course.count
		
		assert Course.find_by_name("import_test").nil?
		## to invoke delayed jobs synchrously
		Delayed::Worker.delay_jobs = false
		post '/en/courses' ,  params: {
					course:{time_zone: "UTC",start_date:"2017-11-08T12:25:14.079Z",end_date:"2018-01-17T10:25:14.079Z",short_name:"test",name:"import_test"},
					import:3,
					subdomains:{All:true},
					email_discussion:false
				}, headers: user.create_new_auth_token
		
		## new course is created
		assert_equal Course.count, initial_course_count + 1
		assert Course.find_by_name("import_test").present?
		
		course_from = Course.find(3)
		new_course =  Course.last
		# compare new and imported groups
		new_course.groups.each_with_index do |new_group, i|
			assert_equal  course_from.groups[i].name, new_group.name
			# compare new and imported lectures
			lectures_from = course_from.groups[i].lectures
			new_group.lectures.each_with_index do |new_lecture, j|
				assert_equal lectures_from[j].name, new_lecture.name
				## difference between courses start_date is 65 days
				assert_equal lectures_from[j].appearance_time.to_date + 65.days, new_lecture.appearance_time.to_date
			end
			# compare quizzes
			quizzes_from = course_from.groups[i].quizzes
			new_group.quizzes.each_with_index do |new_quiz, k|
				assert_equal quizzes_from[k].name, new_quiz.name
			end
			#compare custom_links
			links_from = course_from.groups[i].custom_links
			new_group.custom_links.each_with_index do |new_link, m|
				assert_equal links_from[m].name, new_link.name
			end
			
		end
	end
	
		
	test 'validate save_teachers method for empty invitations' do
		url = '/en/courses/'+ @course1.id.to_s+'/save_teachers/'
		post url ,params: {new_teacher: { email: "a", role: "10"}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors']['email'] , "Email is invalid,Role must exist"
	end	
	
	test 'validate save_teachers method for already_enrolled_in_course teacher' do
		url = '/en/courses/'+ @course1.id.to_s+'/save_teachers/'
		post url ,params: {new_teacher: { email: @user1.email, role: "4"} },headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors']['email'] , "already enrolled in this course"
	end	
	
	test 'validate save_teachers method for new teacher' do
		url = '/en/courses/'+ @course1.id.to_s+'/save_teachers/'
		post url ,params: {new_teacher: { email: @admin_user.email, role: "3"} },headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['nothing'] , true
		assert_equal resp['notice'][0] , 'Saved'
	end	

	test 'validate delete_teacher method invalid email' do
		url = '/en/courses/'+ @course1.id.to_s+'/delete_teacher/'
		delete url ,params: {email: "a"},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors'][0] , "Enter a valid email address"
	end		

	test 'validate delete_teacher method owner can not delete himself' do
		url = '/en/courses/'+ @course1.id.to_s+'/delete_teacher/'
		delete url ,params: {email: @user1.email},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors'][0] , "You cannot delete the course owner"
	end		

	test 'validate delete_teacher method owner delete another teacher' do
		@course1.add_professor(@user2 , false)
		url = '/en/courses/'+ @course1.id.to_s+'/delete_teacher/'
		delete url ,params: {email: @user2.email},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'][0] , "Teacher successfully removed from course"
	end

	test 'validate delete_teacher method not owner delete himself' do
		@course1.add_professor(@user2 , false)
		url = '/en/courses/'+ @course1.id.to_s+'/delete_teacher/'
		delete url ,params: {email: @user2.email},headers: @user2.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'][0] , "Teacher successfully removed from course"
		assert_equal resp['remove_your_self'] , true
	end

	test 'validate delete_teacher method owner delete teacher has no account' do
		@invitation_2 = invitations(:invitation_2)
		@course1.add_professor(@user2 , false)
		url = '/en/courses/'+ @course1.id.to_s+'/delete_teacher/'
		delete url ,params: {email: @invitation_2.email},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'][0] , "Teacher successfully removed from course"
	end

	test 'validate update_teacher method owner update teacher has no account' do
		url = '/en/courses/'+ @course1.id.to_s+'/update_teacher/'
		post url ,params: {"email"=>"a.hossam.2011@gmail.com", "role"=>4, "status"=>"Pending", "name"=>"Ahmed", "last_name"=>"Hossam", "course"=>{"name"=>"Ahmed"}} , headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'][0] , "Saved"
	end

	test 'validate current_courses method ' do
		@course1.end_date = DateTime.now + 1.months
		@course1.save
		url = '/en/courses/current_courses'
		get  url , headers: @user1.create_new_auth_token 
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal resp['teacher_courses'].count , 1
		assert_equal resp['student_courses'].count , 0
	end

	test 'validate current_courses method for admin_user' do
		@course1.end_date = DateTime.now + 1.months
		@course1.save
		url = '/en/courses/current_courses'
		get  url , headers: @admin_user.create_new_auth_token 
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal resp['teacher_courses'].count , 1
		assert_equal resp['student_courses'].count , 0
		@course2.end_date = DateTime.now + 1.months
		@course2.save
		url = '/en/courses/current_courses'
		get  url , headers: @admin_user.create_new_auth_token 
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal resp['teacher_courses'].count , 2
	end

	test 'validate get_role method for teacher' do
		url = '/en/courses/'+ @course1.id.to_s+'/get_role/'
		get  url , headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['role'] , 1
	end
	
	test 'validate get_role method for admin_user' do
		url = '/en/courses/'+ @course1.id.to_s+'/get_role/'
		get  url , headers: @admin_user.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['role'] , 1
	end

	test 'validate update_teacher_discussion_email method for teacher' do
		assert_equal TeacherEnrollment.where( user_id: @user1.id , course_id: @course1.id)[0].email_discussion , false
		url = '/en/courses/'+ @course1.id.to_s+'/update_teacher_discussion_email/'
		post  url , params:{email_discussion: true} , headers: @user1.create_new_auth_token , as: :json
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal TeacherEnrollment.where( user_id: @user1.id , course_id: @course1.id)[0].email_discussion , true
	end

	test 'validate set_selected_subdomains method for teacher' do
		assert_equal @course1.reload.course_domains.count , 1
		url = '/en/courses/'+ @course1.id.to_s+'/set_selected_subdomains/'
		post  url , params: {selected_subdomains: {'All': true},} , headers: @user1.create_new_auth_token , as: :json
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal @course1.reload.course_domains.count , 0		
		assert_equal resp['subdomains'] , true
		url = '/en/courses/'+ @course1.id.to_s+'/set_selected_subdomains/'
		post  url , params: {selected_subdomains: {'gmail': true},} , headers: @user1.create_new_auth_token , as: :json
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal @course1.reload.course_domains.count , 1
	end

	test 'validate enroll_to_course method Enter wrong unique_identifier' do
		url = '/en/courses/enroll_to_course/'
		post url ,params: {unique_identifier: "FDVSE-44759", course:{unique_identifier:"FDVSE-44759"}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors'][0] , "Course does not exist"
	end	

	test 'validate enroll_to_course method user enter unique_identifier for already enroll_to_course' do
		url = '/en/courses/enroll_to_course/'
		post url ,params: {unique_identifier: @course1.unique_identifier, course:{unique_identifier:@course1.unique_identifier}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors'][0] , "You are already enrolled in this course."
	end	

	test 'validate enroll_to_course method user enter unique_identifier for correct user' do
		assert_equal @user4.reload.courses.count , 0 
		url = '/en/courses/enroll_to_course/'
		post url ,params: {unique_identifier: @course1.unique_identifier, course:{unique_identifier:@course1.unique_identifier}},headers: @user4.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'][0] , "You are now enrolled in name"
		assert_equal @user4.reload.courses.count , 1 
	end

	test 'validate enroll_to_course method user enter unique_identifier for correct user twice' do
		assert_equal @user4.reload.courses.count , 0 
		url = '/en/courses/enroll_to_course/'
		post url ,params: {unique_identifier: @course1.unique_identifier, course:{unique_identifier:@course1.unique_identifier}},headers: @user4.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'][0] , "You are now enrolled in name"
		assert_equal @user4.reload.courses.count , 1 
		post url ,params: {unique_identifier: @course1.unique_identifier, course:{unique_identifier:@course1.unique_identifier}},headers: @user4.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors'][0] , "You are already enrolled in this course."		
	end	

	test 'validate enroll_to_course method user enter unique_identifier for correct user after disable_registration' do
		@course1.disable_registration = DateTime.now - 3.days
		@course1.save
		assert_equal @user4.reload.courses.count , 0 
		url = '/en/courses/enroll_to_course/'
		post url ,params: {unique_identifier: @course1.unique_identifier, course:{unique_identifier:@course1.unique_identifier}},headers: @user4.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors'][0] , "Registration is disabled for this course, contact your teacher to enable registration."
		assert_equal @user4.reload.courses.count , 0 
	end	

	test 'validate enroll_to_course method user enter unique_identifier for correct user course domain enabled' do
		@user4.skip_reconfirmation!
		@user4.email = 'hossam@outlook.com'
		@user4.save(:validate => false)
		assert_equal @user4.reload.courses.count , 0 
		url = '/en/courses/enroll_to_course/'
		post url ,params: {unique_identifier: @course1.unique_identifier, course:{unique_identifier:@course1.unique_identifier}},headers: @user4.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors'][0] , "Your school domain is not allowed to register for this course."
		assert_equal @user4.reload.courses.count , 0
	end	

	test 'validate enroll_to_course method user enter guest unique_identifier for correct user' do
		assert_equal @user4.reload.courses.count , 0 
		assert_equal @user4.reload.guest_courses.count , 0 
		url = '/en/courses/enroll_to_course/'
		post url ,params: {unique_identifier: @course1.guest_unique_identifier, course:{unique_identifier:@course1.guest_unique_identifier}},headers: @user4.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['notice'][0] , "You are now enrolled in name"
		assert_equal @user4.reload.courses.count , 0
		assert_equal @user4.reload.guest_courses.count , 1
	end

	test 'validate enrolled_students method for empty course ' do
		url = '/en/courses/'+ @course1.id.to_s+'/enrolled_students/'
		get url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp.count , 0
	end

	test 'validate enrolled_students method for course with 1 student' do
		url = '/en/courses/enroll_to_course/'
		post url ,params: {unique_identifier: @course1.unique_identifier, course:{unique_identifier:@course1.unique_identifier}},headers: @user4.create_new_auth_token 
		url = '/en/courses/'+ @course1.id.to_s+'/enrolled_students/'
		get url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp.count , 1
	end

	test 'validate remove_student method for enrolled_student' do
		url = '/en/courses/enroll_to_course/'
		post url ,params: {unique_identifier: @course1.unique_identifier, course:{unique_identifier:@course1.unique_identifier}},headers: @user4.create_new_auth_token 		
		assert_equal @user4.reload.courses.count , 1 

		url = '/en/courses/'+ @course1.id.to_s+'/remove_student?student='+@user4.id.to_s
		post url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['deleted'] , true
		assert_equal @user4.reload.courses.count , 0
	end	

	test 'validate remove_student method for teacher' do
		url = '/en/courses/'+ @course1.id.to_s+'/remove_student?student='+@user1.id.to_s
		post url ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['deleted'] , false
		assert_equal resp['errors'][0] , "Could not remove "+@user4.name+" from course"
	end	

	test 'validate send_batch_email_through method for teacher' do
		assert_equal Delayed::Job.count , 0
		url = '/en/courses/'+ @course1.id.to_s+'/send_batch_email_through'
		post url, params: {emails:["a.hossam.2011@gmail.com"], subject:"aa", message:"aa" } ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['nothing'] , true
		assert_equal resp['notice'][0] , "Email will be sent shortly"
		assert_equal Delayed::Job.count , 1
	end	

end