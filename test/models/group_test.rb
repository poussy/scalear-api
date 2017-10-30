require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
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
		group = Group.new 
		assert_not group.valid?
		assert_equal [:course, :appearance_time, :course_id, :name, :due_date, :graded, :required ], group.errors.keys
		group.name = 'name'
		group.course_id = @course1.id
		# course.end_date = 'time_zone'
		# assert_not course.valid?
		# assert_equal [ :end_date,  :start_date], course.errors.keys

		group.appearance_time = '2017-9-9'.to_datetime
		group.due_date = '2017-8-9'.to_datetime
		assert_not group.valid?

		assert_equal [ :graded, :required, :due_date ], group.errors.keys
		assert_not group.valid?

		group.due_date = '2017-10-9'.to_datetime
		assert_not group.valid?
		assert_equal [ :graded, :required ], group.errors.keys

		group.graded = false
		group.required = false
		assert group.valid?

		# ## validate the appearance date is before the items appearance date


		# ## validate the due date is after the items due date
	end




end