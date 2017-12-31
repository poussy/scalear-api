require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users('student_in_course3')
    @professor = users('user1')
    @admin = users('admin_user')
    @school_admin = users('school_administrator')
  end
  
  test "get_dashboard for student" do
    Event.all.each do |e|
      e.start_at = Time.now+1.days
      e.save
    end
    
    get '/en/dashboard/get_dashboard', headers: @student.create_new_auth_token

    assert_equal decode_json_response_body['events'].size, Event.where(course_id:3).size
    event1=decode_json_response_body['events'][0]
    assert_equal event1['title'], 'New Module due'
    assert_equal Time.parse(event1['start']).to_i/10.floor, (Time.now+1.days).to_i/10.floor 
    assert_equal event1['color'], '#d1ddf0'
    assert_equal event1['textColor'], '#546d8e'
    assert_equal event1['status'], 0
    assert_equal event1['days'], -1
    assert_equal event1['role'], 2

  end

  test "get_dashboard for professor" do
    Event.all.each do |e|
      e.start_at = Time.now+1.days
      e.save
    end
    
    get '/en/dashboard/get_dashboard', headers: @professor.create_new_auth_token

    assert_equal decode_json_response_body['events'].size, 1
    event1=decode_json_response_body['events'][0]
    assert_equal event1['title'], 'New Module due'
    assert_equal Time.parse(event1['start']).to_i/10.floor, (Time.now+1.days).to_i/10.floor 
    assert_equal event1['color'], 'gray'
    assert_equal event1['textColor'], 'white'
    assert_equal event1['status'], -1
    assert_equal event1['days'], 0
    assert_equal event1['role'], 1

  end

  test "get_dashboard for admin" do
    Event.all.each do |e|
      e.start_at = Time.now+1.days
      e.save
    end
    
    get '/en/dashboard/get_dashboard', headers: @admin.create_new_auth_token

    assert_equal decode_json_response_body['events'].size, 7
    # get '/en/dashboard/get_dashboard', headers: @school_admin.create_new_auth_token
    # pp decode_json_response_body
  end

   test "get_dashboard for school_admin" do

    get '/en/dashboard/get_dashboard', headers: @school_admin.create_new_auth_token
    assert decode_json_response_body['events'].size, 1
    
  end
end
