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
    
    Course.find(3).update_attribute('end_date',Time.now+10.days)
    get '/en/dashboard/get_dashboard', headers: @student.create_new_auth_token

    assert_equal decode_json_response_body['events'].size, Event.where(course_id:3).size
    event1=decode_json_response_body['events'].select{|event| event["id"]==1}[0]
    assert_equal event1['title'], 'New Module due'
    assert_equal Time.parse(event1['start']).to_i/60.floor, (Time.now+1.days).to_i/60.floor 
    assert_equal event1['color'], '#d1ddf0'
    assert_equal event1['textColor'], '#546d8e'
    assert_equal event1['status'], 0
    assert_equal event1['days'], -1
    assert_equal event1['role'], 2

  end

  test "get_dashboard should change event colors and status if course has ended" do
    Event.all.each do |e|
      e.start_at = Time.now+1.days
      e.save
    end
    
    get '/en/dashboard/get_dashboard', headers: @student.create_new_auth_token

    assert_equal decode_json_response_body['events'].size, Event.where(course_id:3).size
    event1=decode_json_response_body['events'].select{|event| event["id"]==1}[0]
    ## this event is in course 3 which has an end date = 2017-10-09
    assert_equal event1['title'], 'New Module due'
    assert_equal Time.parse(event1['start']).to_i/60.floor, (Time.now+1.days).to_i/60.floor 
    assert_equal event1['color'], 'gray'
    assert_equal event1['textColor'], 'white'
    assert_equal event1['status'], -1
    assert_equal event1['days'], 0

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
    assert_equal Time.parse(event1['start']).to_i/100.floor, (Time.now+1.days).to_i/100.floor 
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
  end

  test "get_dashboard for school_admin" do

    get '/en/dashboard/get_dashboard', headers: @school_admin.create_new_auth_token
    assert decode_json_response_body['events'].size, 1
    
  end

  test "dynamic_url should not return event of courses already ended" do
    get '/en/dashboard/dynamic_url', params:{tz:"Africa",key:"rzmk3chbkS3K0QxERP3QFg=="}, headers: @student.create_new_auth_token #key for id 6
    assert_not response.body.include? "DESCRIPTION:c3: New Module"
  
  end

   test "dynamic_url shold return events of courses which didnt end" do
    Course.find(3).update_attribute('end_date',Time.now + 10.days)
    get '/en/dashboard/dynamic_url', params:{tz:"Africa",key:"rzmk3chbkS3K0QxERP3QFg=="}, headers: @student.create_new_auth_token #key for id 6
    
    assert response.body.include? "DESCRIPTION:c3: New Module"
    assert response.body.include? "DTSTART:20170909T000000"
    assert response.body.include? "DTEND:20170909T000000"
    assert response.body.include? "DTSTART:20170909T000000"
    assert response.body.include? "DTEND:20170909T000000"
    assert response.body.include? "LOCATION:Scalable-Learning"
    assert response.body.include? "UID:Scalable-Learning0"
    assert response.body.include? "DTSTAMP:20170909T000000"
  
  end
end
