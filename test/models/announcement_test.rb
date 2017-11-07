require 'test_helper'

class AnnouncementTest < ActiveSupport::TestCase

	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)
		@course1 = courses(:course1)		
	end

	test "Validate model validation" do
		announcement = Announcement.new 
		assert_not announcement.valid?
		assert_equal [:user, :course, :announcement, :date ], announcement.errors.keys
		announcement.announcement = 'announcement'
		announcement.user_id = @user1.id
		announcement.course_id = @course1.id
		announcement.date = 'time_zone'
		assert_not announcement.valid?
		assert_equal [ :date], announcement.errors.keys

		announcement.date = '2017-9-9'.to_datetime
		assert announcement.valid?

		announcement.save	   
	end

end
