require 'test_helper'

class OnlineQuizzesControllerTest < ActionDispatch::IntegrationTest
  def setup

		## @user3 is teacher in @course3
		@user3 = users(:user3)
		@user3.roles << Role.find(1)
		@course3 = courses(:course3)
		@course3.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)
    @online_quiz1 = online_quizzes(:online_quiz1)

		## necessary to send as json, so true and false wouldn't convert to strings
    @headers = @user3.create_new_auth_token
    @headers['content-type']="application/json"
  end

  test "should update online_quiz with sent paramaters" do

    assert_equal @online_quiz1.display_text, true
    assert_equal @online_quiz1.start_time, 100
    assert_equal @online_quiz1.time, 20
    assert_equal @online_quiz1.end_time, 120
    assert_equal @online_quiz1.graded, false
    assert_equal @online_quiz1.inclass, false
    put '/en/online_quizzes/1', params: {online_quiz: {display_text:false, start_time:10, time:40, end_time:50, 
                                                        graded:true, inclass:true, question:"New Quiz"}}, headers: @headers, as: :json
    
    @online_quiz1.reload
    assert_equal @online_quiz1.display_text, false
    assert_equal @online_quiz1.start_time, 10
    assert_equal @online_quiz1.time, 40
    assert_equal @online_quiz1.end_time, 50
    assert_equal @online_quiz1.graded, true
    assert_equal @online_quiz1.inclass, true
  end

  test "should set hide attribute according to inclass" do
    assert_equal @online_quiz1.hide, true

    put '/en/online_quizzes/1', params: {online_quiz: {inclass:true, display_text:false, start_time:10, time:40, end_time:50, 
                                                      graded:true, question:"New Quiz"}}, headers: @headers, as: :json
    @online_quiz1.reload
    assert_equal @online_quiz1.hide, false

    put '/en/online_quizzes/1', params: {online_quiz: {inclass:false, display_text:false, start_time:10, time:40, end_time:50, 
                                                      graded:true, question:"New Quiz"}}, headers: @headers, as: :json
    @online_quiz1.reload
    assert_equal @online_quiz1.hide, true
    
  end

  test "should send alert if another quiz is within 5 seconds" do

     put '/en/online_quizzes/2', params: {online_quiz: {inclass:false, display_text:false, start_time:10, time:22, end_time:50, 
                                                      graded:true, question:"New Quiz"}}, headers: @headers, as: :json
                                                  
    assert_equal decode_json_response_body['alert'], "There's another quiz within 5 seconds from this one - consider shifting it."
    
  end

  test "should send empty response if valid attributes are sent" do

     put '/en/online_quizzes/1/validate_name', params: {online_quiz: {inclass:false, display_text:false, start_time:10, end_time:50, 
                                                      graded:true, question:"New Quiz"}}, headers: @headers, as: :json
                                                  
    assert_response 200
    assert_equal response.headers["Content-length"], "0"

  end

  test "should return list of online_quizzes of lecture" do
    get '/en/online_quizzes/get_quiz_list_angular', params: {lecture_id: 3}, headers: @headers

    lecture = lectures(:lecture3)

    assert_equal decode_json_response_body['quizList'].count, lecture.online_quizzes.count

  end

  test "should add match_type='Free Text' attribute to quiz if question_type is 'Free Text Question'" do

    get '/en/online_quizzes/get_quiz_list_angular', params: {lecture_id: 3}, headers: @headers

    decode_json_response_body['quizList'].each do |q| 
      if q['question_type']=="Free Text Question" && OnlineAnswer.where(online_quiz_id: q['id']).blank?
        assert_equal q['match_type'], "Free Text"
      end
      
    end
  end

  test "should add match_type='Match Text' attribute to quiz " do ## in case question_type is 'Free Text Question' && online_answers.size > 0 && !online_answers.first.answer.blank?

    get '/en/online_quizzes/get_quiz_list_angular', params: {lecture_id: 3}, headers: @headers


    decode_json_response_body['quizList'].each do |q| 
      if q['question_type']=="Free Text Question" && OnlineAnswer.where(online_quiz_id: q['id']).count > 0 && !OnlineAnswer.where(online_quiz_id: q['id']).first.answer.blank?
        assert_equal q['match_type'], "Match Text"
      end
      
    end

    
  end
  

end
