require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
	
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)
		@user3 = users(:user3)
		@invitated_user = users(:invitated_user)
		@student7_in_course3 = users(:student7_in_course3)

		@course1 = courses(:course1)
		@course2 = courses(:course2)
		@course3 = courses(:course3)

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

	test "return shared items for user" do
		user = users(:user3)
		get '/en/home/notifications' ,headers: user.create_new_auth_token 
		resp =  JSON.parse response.body
		resp["shared_items"].each do |key, value|
			value["data"] = user.shared_withs.find(key)["data"]
			value["sharer_email"] = user.shared_withs.find(key).sharer_email
		end	
	end
	
	test "return index" do
		get '/en/home/index' ,headers: @user3.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp , {}
	end	

	test "return privacy" do
		get '/en/home/privacy' ,headers: @user3.create_new_auth_token 
		assert_redirected_to '#/privacy'
	end	

	test "return about" do
		get '/en/home/about' ,headers: @user3.create_new_auth_token 
		assert_redirected_to '#/about'
	end	

	test "technical_problem using user_mailer#content_problem_email method with group id" do		
		Delayed::Worker.delay_jobs = false
		deliveries_count =  ActionMailer::Base.deliveries.count 
		get '/en/home/technical_problem', params:{url: 'localhost', problem:'this is for testing', issue_type:'content' ,   course: 3, module:3 , agent: 'chrome' , version: '1.2.3.4'}, headers: @user3.create_new_auth_token		

		assert_equal ActionMailer::Base.deliveries.count , deliveries_count+ 1
		assert_equal ActionMailer::Base.deliveries.last["bcc"].value, ["karim@novelari.com"]
		assert_equal ActionMailer::Base.deliveries.last["reply-to"].value, "okasha@gmail.com"		
		subject = @course3.short_name.to_s 
		subject += " Student help request "
		assert_equal ActionMailer::Base.deliveries.last["subject"].value, subject

		assert ActionMailer::Base.deliveries.last.encoded.include?('1.2.3.4')
		assert ActionMailer::Base.deliveries.last.encoded.include?('chrome')
		assert ActionMailer::Base.deliveries.last.encoded.include?('this is for testing')
	end

	test "technical_problem using user_mailer#content_problem_email method with lecture id" do		
		Delayed::Worker.delay_jobs = false
		deliveries_count =  ActionMailer::Base.deliveries.count 
		get '/en/home/technical_problem', params:{url: 'localhost', problem:'this is for testing', issue_type:'content' ,   course: 3, module:-1, lecture:3 , agent: 'chrome' , version: '1.2.3.4'}, headers: @user3.create_new_auth_token		

		assert_equal ActionMailer::Base.deliveries.count , deliveries_count+ 1
		assert_equal ActionMailer::Base.deliveries.last["bcc"].value, ["karim@novelari.com"]
		assert_equal ActionMailer::Base.deliveries.last["reply-to"].value, "okasha@gmail.com"		
		subject = @course3.short_name.to_s 
		subject += " Student help request "
		assert_equal ActionMailer::Base.deliveries.last["subject"].value, subject

		assert ActionMailer::Base.deliveries.last.encoded.include?('1.2.3.4')
		assert ActionMailer::Base.deliveries.last.encoded.include?('chrome')
		assert ActionMailer::Base.deliveries.last.encoded.include?('this is for testing')
	end

	test "technical_problem using user_mailer#content_problem_email method with quiz id" do		
		Delayed::Worker.delay_jobs = false
		deliveries_count =  ActionMailer::Base.deliveries.count 
		get '/en/home/technical_problem', params:{url: 'localhost', problem:'this is for testing', issue_type:'content' ,   course: 3, module: -1, lecture:-1 ,quiz:1 , agent: 'chrome' , version: '1.2.3.4'}, headers: @user3.create_new_auth_token		

		assert_equal ActionMailer::Base.deliveries.count , deliveries_count+ 1
		assert_equal ActionMailer::Base.deliveries.last["bcc"].value, ["karim@novelari.com"]
		assert_equal ActionMailer::Base.deliveries.last["reply-to"].value, "okasha@gmail.com"		
		subject = @course3.short_name.to_s 
		subject += " Student help request "
		assert_equal ActionMailer::Base.deliveries.last["subject"].value, subject

		assert ActionMailer::Base.deliveries.last.encoded.include?('1.2.3.4')
		assert ActionMailer::Base.deliveries.last.encoded.include?('chrome')
		assert ActionMailer::Base.deliveries.last.encoded.include?('this is for testing')
	end

	test "technical_problem using user_mailer#content_problem_email method" do		
		Delayed::Worker.delay_jobs = false
		deliveries_count =  ActionMailer::Base.deliveries.count 
		get '/en/home/technical_problem', params:{url: 'localhost', problem:'this is for testing', issue_type:'content' ,   course: 3, module:3 , agent: 'chrome' , version: '1.2.3.4'}, headers: @user3.create_new_auth_token		

		assert_equal ActionMailer::Base.deliveries.count , deliveries_count+ 1
		assert_equal ActionMailer::Base.deliveries.last["bcc"].value, ["karim@novelari.com"]
		assert_equal ActionMailer::Base.deliveries.last["reply-to"].value, "okasha@gmail.com"		
		subject = @course3.short_name.to_s 
		subject += " Student help request "
		assert_equal ActionMailer::Base.deliveries.last["subject"].value, subject

		assert ActionMailer::Base.deliveries.last.encoded.include?('1.2.3.4')
		assert ActionMailer::Base.deliveries.last.encoded.include?('chrome')
		assert ActionMailer::Base.deliveries.last.encoded.include?('this is for testing')
	end


	test "technical_problem using user_mailer#content_problem_email method WITHOUT user login " do
		
		Delayed::Worker.delay_jobs = false
		deliveries_count =  ActionMailer::Base.deliveries.count 
		get '/en/home/technical_problem', params:{url: 'localhost', problem:'this is for testing', issue_type:'content' ,   course: 3, module:3 , agent: 'chrome' , version: '1.2.3.4'}		

		
		assert_equal ActionMailer::Base.deliveries.count , deliveries_count+ 1
		assert_equal ActionMailer::Base.deliveries.last["bcc"].value, ["karim@novelari.com"]
		assert_equal ActionMailer::Base.deliveries.last["reply-to"].value, ""		
		subject = @course3.short_name.to_s 
		subject += " Student help request "
		assert_equal ActionMailer::Base.deliveries.last["subject"].value, subject

		assert ActionMailer::Base.deliveries.last.encoded.include?('1.2.3.4')
		assert ActionMailer::Base.deliveries.last.encoded.include?('chrome')
		assert ActionMailer::Base.deliveries.last.encoded.include?('this is for testing')
	end

	test "technical_problem using user_mailer#technical_problem_email method with group_id" do
		
		Delayed::Worker.delay_jobs = false
		deliveries_count =  ActionMailer::Base.deliveries.count 
		get '/en/home/technical_problem', params:{url: 'localhost', problem:'this is for testing', issue_type:'not_content' ,   course: 3, module:3 , agent: 'chrome' , version: '1.2.3.4', issue_website_type:'issue_website_type'}, headers: @user3.create_new_auth_token		

		assert_equal ActionMailer::Base.deliveries.count , deliveries_count+ 1
		assert_equal ActionMailer::Base.deliveries.last["bcc"].value, [""]
		assert_equal ActionMailer::Base.deliveries.last["reply-to"].value, "okasha@gmail.com"
		assert_equal ActionMailer::Base.deliveries.last["to"].value, ["teacher-support@scalear.zendesk.com"]
		assert_equal ActionMailer::Base.deliveries.last["subject"].value, 'ScalableLearning Technical Problem: issue_website_type'

		assert ActionMailer::Base.deliveries.last.encoded.include?('1.2.3.4')
		assert ActionMailer::Base.deliveries.last.encoded.include?('chrome')
		assert ActionMailer::Base.deliveries.last.encoded.include?('this is for testing')
		assert ActionMailer::Base.deliveries.last.encoded.include?('issue_website_type')
	end

	test "technical_problem using user_mailer#technical_problem_email method with lecture_id" do
		
		Delayed::Worker.delay_jobs = false
		deliveries_count =  ActionMailer::Base.deliveries.count 
		get '/en/home/technical_problem', params:{url: 'localhost', problem:'this is for testing', issue_type:'not_content' ,   course: 3, module: -1 ,lecture:3 , agent: 'chrome' , version: '1.2.3.4', issue_website_type:'issue_website_type'}, headers: @user3.create_new_auth_token		

		assert_equal ActionMailer::Base.deliveries.count , deliveries_count+ 1
		assert_equal ActionMailer::Base.deliveries.last["bcc"].value, [""]
		assert_equal ActionMailer::Base.deliveries.last["reply-to"].value, "okasha@gmail.com"
		assert_equal ActionMailer::Base.deliveries.last["to"].value, ["teacher-support@scalear.zendesk.com"]
		assert_equal ActionMailer::Base.deliveries.last["subject"].value, 'ScalableLearning Technical Problem: issue_website_type'

		assert ActionMailer::Base.deliveries.last.encoded.include?('1.2.3.4')
		assert ActionMailer::Base.deliveries.last.encoded.include?('chrome')
		assert ActionMailer::Base.deliveries.last.encoded.include?('this is for testing')
		assert ActionMailer::Base.deliveries.last.encoded.include?('issue_website_type')
	end

	test "contact_us using user_mailer#contact_us_email method" do
		
		Delayed::Worker.delay_jobs = false
		deliveries_count =  ActionMailer::Base.deliveries.count 
		get '/en/home/contact_us', params:{url: 'localhost', comment:'this is for testing',  agent: 'chrome'}, headers: @user3.create_new_auth_token		

		assert_equal ActionMailer::Base.deliveries.count , deliveries_count+ 1
		assert_equal ActionMailer::Base.deliveries.last["to"].value, ["teacher-support@scalear.zendesk.com"]
		assert_equal ActionMailer::Base.deliveries.last["subject"].value, 'ScalableLearning Homepage Contact Request'

		assert ActionMailer::Base.deliveries.last.encoded.include?('this is for testing')
	end

	test "technical_problem using user_mailer#technical_problem_email method with quiz_id" do
		Delayed::Worker.delay_jobs = false
		get '/en/home/technical_problem', params:{url: 'localhost', problem:'this is for testing', issue_type:'not_content' ,   course: 3, module: -1 ,lecture: -1, quiz: 1  , agent: 'chrome' , version: '1.2.3.4', issue_website_type:'issue_website_type'}, headers: @student7_in_course3.create_new_auth_token
		ActionMailer::Base.deliveries.each do |delivery| 
			if delivery["subject"].value == 'issue_website_type'
				assert_equal delivery["subject"].value, 'issue_website_type'
				assert_equal delivery["bcc"].value, [""]
				assert_equal delivery["reply-to"].value, "ahmed@gmail.com"
				assert_equal delivery["to"].value, ["student-support@scalear.zendesk.com"]

				assert delivery.encoded.include?('1.2.3.4')
				assert delivery.encoded.include?('chrome')
				assert delivery.encoded.include?('this is for testing')
				assert delivery.encoded.include?('issue_website_type')
			end
		end
	end

end
