require 'test_helper'

class InvitationTest < ActiveSupport::TestCase
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)

		@course1 = courses(:course1)

		@invitation1 = invitations(:invitation1)
	end

	test "Validate model validation" do
		invitation = Invitation.new 
		assert_not invitation.valid?

		assert_equal [:email, :course, :user, :role ], invitation.errors.keys
		invitation.email = 'a.hossam.20'
		assert_not invitation.valid?
		assert_equal invitation.errors['email'][0], "is invalid"

		invitation.role_id = 3
		invitation.user = @user1
		invitation.course = @course1

		invitation.email = 'a.hossam.2011@gmail.com'
		assert_not invitation.valid?
		assert_equal invitation.errors['email'][0], "already invited"

		invitation.email = 'a.hossam.2012@gmail.com'
		assert invitation.valid?

		invitation.save	   
		assert invitation.valid?
	end

end