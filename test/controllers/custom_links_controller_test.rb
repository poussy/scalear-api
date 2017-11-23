require 'test_helper'

class CustomLinksControllerTest < ActionDispatch::IntegrationTest
  def setup
    ## create user for authorization, and set this user to be a teacher in course3, below tests wil use items in course3
    @user = users(:user3)

		@user.roles << Role.find(1)
	
		@course = courses(:course3)

		@course.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)
    
  end
  

  test "should update link information" do

		link = CustomLink.find(1)

    assert_equal link.url, "http://www.youtube.com"

		put '/en/custom_links/1', params:{:link => {:course_id => 3, :group_id => 3, :name => "url3", :url => "http://www.google.com"}},headers: @user.create_new_auth_token

    link.reload
		
    assert_equal link.url, "http://www.google.com"
		
	end

  test "should delete link" do

    assert CustomLink.exists?(1)

		delete '/en/custom_links/1', headers: @user.create_new_auth_token

		
		assert_not CustomLink.exists?(1)
	end

  test "should copy link" do

   
		post '/en/custom_links/2/link_copy',params: {course_id: 3, module_id: 3}, headers: @user.create_new_auth_token

		link_from = CustomLink.find(2)
    new_link = CustomLink.last

    assert_equal link_from.name, new_link.name
    assert_equal link_from.url, new_link.url

    assert_not_equal link_from.id, new_link.id
		
	end

    test 'validate validate_custom_link method ' do
        url = '/en/custom_links/1/validate_custom_link/'
        put  url , params: {link: { name:'toto' } } ,headers: @user.create_new_auth_token , as: :json
        assert_response :success
        resp =  JSON.parse response.body
        assert_equal resp['nothing'] , true
    end
    test 'validate validate_custom_link method and respone 422 for name is empty' do
        url = '/en/custom_links/1/validate_custom_link/'
        put  url , params: {link: { name:'' }} ,headers: @user.create_new_auth_token 
        assert_response 422
        resp =  JSON.parse response.body
        assert_equal resp['errors'].count , 1
        assert_equal resp['errors'][0] , "Name can't be blank"
    end
    test 'validate validate_custom_link method and respone 422 for url is empty' do
        url = '/en/custom_links/1/validate_custom_link/'
        put  url , params: {link: { url:'' }} ,headers: @user.create_new_auth_token 
        assert_response 422
        resp =  JSON.parse response.body
        assert_equal resp['errors'].count , 1
        assert_equal resp['errors'][0] , "Url can't be blank"
    end

end
