require 'test_helper'

class CourseTest < ActiveSupport::TestCase
	def setup
		@role = Role.create(:name=>"User")
		@role.update_column(:id, 1)
		@role = Role.create(:name=>"Student")
		@role.update_column(:id, 2)
		@role = Role.create(:name=>"Professor")
		@role.update_column(:id, 3)
		@role = Role.create(:name=>"Teaching Assistant")
		@role.update_column(:id, 4)
		@role = Role.create(:name=>"Administrator")
		@role.update_column(:id, 5)
		@role = Role.create(:name=>"Preview")
		@role.update_column(:id, 6)
		@role = Role.create(:name=>"School Administrator")
		@role.update_column(:id, 9)
		@user1 = User.create({ name: "ahmed", email: "a.hossam.2010@gmail.com", last_name: "hossam", screen_name: "ahmed hossam", university: "nile",password:'password1234', password_confirmation:'password1234'})
		assert Role.count == 7
		assert User.count == 1
		assert @user1.roles.count == 1
		assert @user1.roles.first.name == "User"

		@user2 = User.create({ name: "ahmed", email: "a.hossamm.2010@gmail.com", last_name: "hossam", screen_name: "ahmed hossam", university: "nile",password:'password1234', password_confirmation:'password1234'})

		@course1 = Course.new
		@course1.name = 'name'
		@course1.short_name = 'short_name'
		@course1.user_id = @user1.id
		@course1.time_zone = "time_zone"
		@course1.start_date = '2017-9-9'.to_datetime
		@course1.end_date = '2017-10-9'.to_datetime
		@course1.valid?	   
		@course1.image_url = 'https://pbs.twimg.com/profile_images/839721704163155970/LI_TRk1z_400x400.jpg'
		assert @course1.valid?
		@course1.save
		@course1.add_professor(@user1 , false)

		@course2 = Course.new
		@course2.name = 'name'
		@course2.short_name = 'short_name'
		@course2.user_id = @user2.id
		@course2.time_zone = "time_zone"
		@course2.start_date = '2017-9-9'.to_datetime
		@course2.end_date = '2017-10-9'.to_datetime
		assert @course2.valid?
		@course2.save
		@course2.add_professor(@user2 , false)
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


		## Validate A course can not change unique_identifier or guest_unique_identifier
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

		course2.unique_identifier = course.unique_identifier
		assert_not course2.valid?
		assert_equal [ :unique_identifier], course2.errors.keys


		## Validate A course must have a guest enrollment key
		## validate A course must have a unique enrollment key
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
		course3.unique_identifier = course2.guest_unique_identifier
		course3.guest_unique_identifier = course2.guest_unique_identifier
		assert course3.valid?
		course3.save	   
	end




end