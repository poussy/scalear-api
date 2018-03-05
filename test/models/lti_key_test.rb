require 'test_helper'

class LtiKeyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)
		@organization_sv = organizations(:organization_sv)
	end

	test 'create lti_key for user' do
		lti_key_user = LtiKey.new( :user_id =>  @user1.id)
		assert lti_key_user.valid?
		assert_nil lti_key_user.organization_id 
		assert_difference [ 'LtiKey.count'] do
			lti_key_user.save
		end
	end
	
	test 'can not create lti_key for user twice' do
		lti_key_user = LtiKey.new( :user_id =>  @user1.id)
		assert lti_key_user.valid?
		assert_nil lti_key_user.organization_id 		
		assert_difference [ 'LtiKey.count'] do
			lti_key_user.save
		end
		lti_key_user = LtiKey.new( :user_id =>  @user1.id)
		assert_not lti_key_user.valid?
		assert_equal [:user_id], lti_key_user.errors.keys
		assert_equal lti_key_user.errors.messages[:user_id][0] , "has already been taken"
	end

	test 'create lti_key for organization' do
		lti_key_organization = LtiKey.create( :organization_id =>  @organization_sv.id)  
		assert lti_key_organization.valid?		
		assert_nil lti_key_organization.user_id 
	end

	test 'Can not create lti_key for empty user and organization' do
		lti_key_user = LtiKey.create()  
		assert_not lti_key_user.valid?
		assert_nil lti_key_user.user_id 
		assert_nil lti_key_user.organization_id 
		assert_equal [:user], lti_key_user.errors.keys
		assert_equal lti_key_user.errors.messages[:user][0] , "Specify a user or a organization, not both"
	end

end
