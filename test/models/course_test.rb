require 'test_helper'

class CourseTest < ActiveSupport::TestCase
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)
		@course1 = courses(:course1)		
	end

	test "Validate model validation" do
		course = Course.new 
		assert_not course.valid?
		assert_equal [:user, :name, :end_date, :short_name, :start_date, :user_id, :time_zone ], course.errors.keys
		course.name = 'name'
		course.short_name = 'short_name'
		course.user_id = @user1.id
		course.time_zone = "time_zone"
		course.start_date = 'time_zone'
		course.end_date = 'time_zone'
		assert_not course.valid?
		assert_equal [ :end_date,  :start_date], course.errors.keys

		course.start_date = '2017-9-9'.to_datetime
		course.end_date = '2017-8-9'.to_datetime
		assert_not course.valid?

		course.start_date = '2017-9-9'.to_datetime
		course.end_date = '2017-10-9'.to_datetime
		assert course.valid?	   

		course.disable_registration = '2017-8-9'.to_datetime
		assert_not course.valid?
		assert_equal [:disable_registration], course.errors.keys

		course.disable_registration = '2017-9-9'.to_datetime
		assert course.valid?

		course.image_url = '2017-8-9'.to_datetime
		assert_not course.valid?
		assert_equal [ :image_url], course.errors.keys

		course.image_url = 'https://www.facebook.com/'
		assert_not course.valid?
		assert_equal [ :image_url], course.errors.keys

		course.image_url = 'https://pbs.twimg.com/profile_images/839721704163155970/LI_TRk1z_400x400.jpg'

		course.save	   
		assert course.valid?
	end

	test "Validate A course can not change unique_identifier or guest_unique_identifier" do 
		course2 = Course.new
		course2.name = 'name'
		course2.short_name = 'short_name'
		course2.user_id = @user2.id
		course2.time_zone = "time_zone"
		course2.start_date = '2017-9-9'.to_datetime
		course2.end_date = '2017-10-9'.to_datetime
		assert course2.valid?	   
		course2.image_url = 'https://pbs.twimg.com/profile_images/839721704163155970/LI_TRk1z_400x400.jpg'
		assert course2.valid?
		course2.save	   

		course2.unique_identifier = @course1.unique_identifier
		assert_not course2.valid?
		assert_equal [ :unique_identifier], course2.errors.keys
	end

	test "Validate A course must have a unique enrollment key && guest enrollment key" do 
		course3 = Course.new
		course3.name = 'name'
		course3.short_name = 'short_name'
		course3.user_id = @user2.id
		course3.time_zone = "time_zone"
		course3.start_date = '2017-9-9'.to_datetime
		course3.end_date = '2017-10-9'.to_datetime
		assert course3.valid?	   
		course3.image_url = 'https://pbs.twimg.com/profile_images/839721704163155970/LI_TRk1z_400x400.jpg'
		assert course3.valid?
		course3.unique_identifier = @course1.guest_unique_identifier
		course3.guest_unique_identifier = @course1.guest_unique_identifier
		assert course3.valid?
		course3.save	   
	end




end