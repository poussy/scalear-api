require 'test_helper'

class KpisControllerTest < ActionDispatch::IntegrationTest

	def setup
		@user3 = users(:user3)
		@admin_user = users(:admin_user)
		ENV['INFLUXDB_PORT'] = "3"
	end

	test "should read_totals_for_duration" do
		raw_start_date = '2017-9-1'
		raw_end_date = "2017-11-1"
		start_date = DateTime.parse(raw_start_date).midnight
		end_date = DateTime.parse(raw_end_date).midnight

		#  using '2017-7-4' to only select 2 courses
		unique_start =  DateTime.parse('2017-7-4')
		total_courses = Course.where('start_date BETWEEN ? AND ?', unique_start.beginning_of_day, unique_start.end_of_day)

		url = '/en/kpis/read_totals_for_duration'
		get url ,params: { start_date:raw_start_date , end_date: raw_end_date, course_ids: total_courses.pluck(:id).to_json},headers: @admin_user.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal resp['total_courses'] , total_courses.count 
		assert_equal resp['total_students'] , total_courses.map{|course| course.enrollments.count}.sum
		assert_equal resp['total_teachers'] , total_courses.map{|course| course.teacher_enrollments.count}.sum
	end	

	test "should get_report_data_course_duration" do
		raw_start_date = '2017-9-1'
		raw_end_date = "2017-11-1"
		start_date = DateTime.parse(raw_start_date).midnight
		end_date = DateTime.parse(raw_end_date).midnight

		#  using '2017-7-4' to only select 2 courses
		unique_start =  DateTime.parse('2017-7-4')
		total_courses = Course.where('start_date BETWEEN ? AND ?', unique_start.beginning_of_day, unique_start.end_of_day)
		total_courses_ids = total_courses.pluck(:id)
		url = '/en/kpis/get_report_data_course_duration'
		post url ,params: { start_date:raw_start_date , end_date: raw_end_date, course_ids: total_courses_ids},headers: @admin_user.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal resp['total_online_quiz_solved'] ,  2
		total_courses.each do |course|
			assert_equal resp['course_data'][course.id.to_s]['short_name'] ,  course.short_name
			assert_equal resp['course_data'][course.id.to_s]['email'] ,  course.user.email
			assert_equal resp['course_data'][course.id.to_s]['teachers'] ,  course.teacher_enrollments.count
			assert_equal resp['course_data'][course.id.to_s]['students'] ,  course.enrollments.count
			assert_equal resp['course_data'][course.id.to_s]['total_solved_online_quiz'] ,  course.online_quiz_grades.count + course.free_online_quiz_grades.count 

		end
	end	
	
end
