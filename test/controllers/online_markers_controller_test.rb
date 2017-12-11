require 'test_helper'

class OnlineMarkersControllerTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end


	def setup
	## create user for authorization, and set this user to be a teacher in course3, below tests wil use items in course3
		@user1 = users(:user1)
		@user2 = users(:user2)

		@course1 = courses(:course1)
		@course2 = courses(:course2)

		@group1 = groups(:group1)

		@lecture1 = lectures(:lecture1)

		@online_marker1 = online_markers(:online_marker1)
		@online_marker2 = online_markers(:online_marker2)
	end	

	test "should validate_name " do
		url = '/en/online_markers/'+@online_marker1.id.to_s+'/validate_name'
		put url , params: {online_marker: {title: "<p class='medium-editor-p'>sada</p>",time: 11.2}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_response :success		
	end
	test "should validate_name empty title" do
		url = '/en/online_markers/'+@online_marker1.id.to_s+'/validate_name'
		put url , params: {online_marker: {title: "",time: '11.2'}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_response :success		
	end
	test "should validate_name for wrong online_marker id" do
		url = '/en/online_markers/'+@online_marker2.id.to_s+'/validate_name'
		put url , params: {online_marker: {title: "",time: 'sadasdas'}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_response 403
		assert_equal resp['errors'][0] , "You are not authorized to see requested page"
	end
	test "should validate_name time invalid" do
		url = '/en/online_markers/'+@online_marker1.id.to_s+'/validate_name'
		put url , params: {online_marker: {title: "",time: 'sadasdas'}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['errors'][0] , "Time is not a number"
		assert_response 422
	end

	test "should update " do
		assert_equal @online_marker1.title , 'title'
		url = '/en/online_markers/'+@online_marker1.id.to_s
		put url , params: {online_marker: {annotation:"<p class='medium-editor-p'>sadasd</p>",time: 133.182011, title: "<p class='medium-editor-p'>sada</p>"}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal @online_marker1.reload.title , "<p class='medium-editor-p'>sada</p>"
		assert_equal @online_marker1.reload.annotation , "<p class='medium-editor-p'>sadasd</p>"
		assert_response :success
	end
	test "should update empty title" do
		assert_equal @online_marker1.title , 'title'
		url = '/en/online_markers/'+@online_marker1.id.to_s
		put url , params: {online_marker: {title:"",time: 133.182011, annotation: "<p class='medium-editor-p'>sada</p>"}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal @online_marker1.reload.title , ""
		assert_equal @online_marker1.reload.annotation , "<p class='medium-editor-p'>sada</p>"
		assert_response :success
	end
	test "should update empty annotation && title" do
		assert_equal @online_marker1.annotation , 'short_title'
		url = '/en/online_markers/'+@online_marker1.id.to_s
		put url , params: {online_marker: {annotation:"",time: 133.182011, title: ""}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal @online_marker1.reload.title , ""
		assert_equal @online_marker1.reload.annotation , ""
		assert_response :success
	end
	test "should update empty zero time" do
		assert_equal @online_marker1.reload.time , 11.2
		url = '/en/online_markers/'+@online_marker1.id.to_s
		put url , params: {online_marker: {annotation:"",time: 'sadasdas', title: ""}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_response 422
		assert_equal resp['errors']['time'][0] , "is not a number"
		assert_equal @online_marker1.reload.time , 11.2
	end

	test "should destroy " do
		assert_equal @course1.reload.online_markers.count , 1
		url = '/en/online_markers/'+@online_marker1.id.to_s
		delete url , params: {online_marker: {annotation:"<p class='medium-editor-p'>sadasd</p>",time: 133.182011, title: "<p class='medium-editor-p'>sada</p>"}},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal @course1.reload.online_markers.count , 0
		assert_equal resp['notice'][0] , "Note was successfully deleted."		
	end

	test "should get_marker_list" do
		assert_equal @course1.reload.online_markers.count , 1
		url = '/en/online_markers/get_marker_list'
		get url , params: {lecture_id: @lecture1.id.to_s}, headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['markerList'].count , 1
		assert_response :success
		@online_marker2.lecture_id = @lecture1.id
		@online_marker2.group_id = @group1.id
		@online_marker2.course_id = @course1.id
		@online_marker2.save
		assert_equal @course1.reload.online_markers.count , 2
		get url , params: {lecture_id: @lecture1.id.to_s}, headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['markerList'].count , 2
		assert_response :success
	end
end
