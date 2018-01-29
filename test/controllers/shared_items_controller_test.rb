require 'test_helper'

class SharedItemsControllerTest < ActionDispatch::IntegrationTest

  def setup
    ## create user for authorization, and set this user to be a teacher in course3, below tests wil use items in course3
    @user = users(:user3)

		@user.roles << Role.find(1)
	
    @headers = @user.create_new_auth_token
    @headers['content-type']="application/json"
    
  end
 
 test "should create shared_item with right params" do

   post '/en/shared_items', params: {shared_item:{data: {modules:[2,1],lectures:[3],quizzes:[1],customlinks:[5]}},shared_with: "okasha@gmail.com"}, headers: @headers, as: :json

   assert_equal SharedItem.last.shared_with, User.find_by_email("okasha@gmail.com")
   assert_equal SharedItem.last.data['modules'], [2,1]
   assert_equal SharedItem.last.data['lectures'], [3]
   assert_equal SharedItem.last.data['quizzes'], [1]
   assert_equal SharedItem.last.data['customlinks'], [5]
 end

 test "should accept shared_item" do

   assert_not SharedItem.find(1).accept

   post '/en/shared_items/1/accept_shared', headers: @headers

   assert SharedItem.find(1).accept

 end

 test "should return number of remaining unaccepted shares" do

   total_shared = @user.shared_withs.where(:accept => false).size
   
   post '/en/shared_items/1/accept_shared', headers: @headers

   assert_equal decode_json_response_body["shared_items"], total_shared - 1

 end

 test "reject_shared should delete shared_item" do

   total_shared = @user.shared_withs.size
   
   post '/en/shared_items/1/reject_shared', headers: @headers

   assert_equal @user.shared_withs.size, total_shared - 1
 end

 test "should show accepted shared items for user" do

    post '/en/shared_items/1/accept_shared', headers: @headers
    
    get '/en/shared_items/show_shared', headers: @headers
    shared_item = SharedItem.find(1)

    assert_not decode_json_response_body["all_shared"].empty?

    ## shared_by id
    assert decode_json_response_body["all_shared"].key?("4")

    ## shared_by email
    assert_equal decode_json_response_body["all_shared"][shared_item.shared_by_id.to_s][0]["teacher"]["email"], "okashaaa@gmail.com"

    ## modules
    decode_json_response_body["all_shared"][shared_item.shared_by_id.to_s][0]["modules"].each_with_index do |m,i|
      
      assert_equal m["id"], shared_item["data"]["modules"][i]
      m.each do |key, value|
          real_value = Group.find(shared_item["data"]["modules"][i])[key]
          if key == "description"
            assert_equal value, Group.find(shared_item["data"]["modules"][i]).course.name
          elsif key == "items"
            assert_equal value.size, Group.find(shared_item["data"]["modules"][i]).get_items.size
          elsif key == "total_time"
            assert_equal value, Group.find(shared_item["data"]["modules"][i]).total_time
          elsif key == "total_questions"
            assert_equal value, Group.find(shared_item["data"]["modules"][i]).total_questions
          elsif key == "total_quiz_questions"
            assert_equal value, Group.find(shared_item["data"]["modules"][i]).total_quiz_questions
          elsif real_value.is_a?(ActiveSupport::TimeWithZone)
            real_value = real_value.to_datetime 
            value = value.to_datetime
            
            assert_in_delta real_value, value, 1.second
          elsif real_value.nil?
            assert value.nil? || value== 0
          else
            
            assert_equal real_value, value
          end
      end
    end

    ## lectures  
    decode_json_response_body["all_shared"][shared_item.shared_by_id.to_s][0]["lectures"].each_with_index do |l,i|
      assert_equal l["id"], shared_item["data"]["lectures"][i]
      l.each do |key, value|
          real_value = Lecture.find(shared_item["data"]["lectures"][i])[key]
          if real_value.is_a?(ActiveSupport::TimeWithZone)
            real_value = real_value.to_datetime 
            value = value.to_datetime
            assert_in_delta real_value, value, 1.second
          elsif real_value.nil?
            assert_nil value
          else
            assert_equal real_value, value
          end
      end
    end

    ## quizzes
    decode_json_response_body["all_shared"][shared_item.shared_by_id.to_s][0]["quizzes"].each_with_index do |q,i|
      assert_equal q["id"], shared_item["data"]["quizzes"][i]
      q.each do |key, value|
        real_value = Quiz.find(shared_item["data"]["quizzes"][i])[key]
        if real_value.is_a?(ActiveSupport::TimeWithZone)
          real_value = real_value.to_datetime 
          value = value.to_datetime
          assert_in_delta real_value, value, 1.second
        elsif real_value.nil?
          assert_nil value
        else
          assert_equal real_value, value
        end
      end
    end
    
    ## custom_links
    decode_json_response_body["all_shared"][shared_item.shared_by_id.to_s][0]["customlinks"].each_with_index do |c,i|
      assert_equal c["id"], shared_item["data"]["customlinks"][i]
      c.each do |key, value|
        real_value = CustomLink.find(shared_item["data"]["customlinks"][i])[key]
        if real_value.is_a?(ActiveSupport::TimeWithZone)
          real_value = real_value.to_datetime 
          value = value.to_datetime

          assert_in_delta real_value, value, 1.second
        elsif real_value.nil?
          assert_nil value
        else
          assert_equal real_value, value
        end
      end
      
    end
  end

  test "should update_shared_data shared_item and check data is updated and correct in database " do
    assert_equal SharedItem.first.reload.data['modules'] , [4, 3, 5] 
    post  '/en/shared_items/1/update_shared_data', params: {data:{modules:[{id:4}], customlinks:[], quizzes:[], lectures: [] } } , headers: @headers, as: :json
    assert_response :success
    assert_equal SharedItem.first.reload.data['modules'] , [4]
    resp =  JSON.parse(response.body)
    assert_equal resp , {}
  end

end
