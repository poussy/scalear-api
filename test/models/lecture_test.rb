require 'test_helper'

class LectureTest < ActiveSupport::TestCase
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

		@course1 = Course.new ({name: 'name' , short_name: 'short_name' , user_id: @user1.id , time_zone: "time_zone" , start_date: '2017-9-4'.to_datetime , end_date: '2017-10-9'.to_datetime , image_url: 'https://pbs.twimg.com/profile_images/839721704163155970/LI_TRk1z_400x400.jpg' })
		assert @course1.valid?

		@course1.save
		@course1.add_professor(@user1 , false)

		@course2 = Course.new ({name: 'name' , short_name: 'short_name' , user_id: @user2.id , time_zone: "time_zone" , start_date: '2017-9-4'.to_datetime , end_date: '2017-10-9'.to_datetime , image_url: 'https://pbs.twimg.com/profile_images/839721704163155970/LI_TRk1z_400x400.jpg' })
		assert @course2.valid?
		@course2.save
		@course2.add_professor(@user2 , false)

		@group1 = Group.new({name: 'name',course_id: @course1.id,appearance_time: '2017-9-9'.to_datetime,due_date: '2017-10-9'.to_datetime,graded: false,required: false,position: 1})

		assert @group1.valid?
		@group1.save
		assert Group.count == 1

		@group2 = Group.new({name: 'name',course_id: @course2.id,appearance_time: '2017-9-9'.to_datetime,due_date: '2017-10-9'.to_datetime,graded: false,required: false,position: 1})
		assert @group2.valid?
		@group2.save
		assert Group.count == 2
	end

	test "Validate model validation" do
		@lecture1 = Lecture.new 
		assert_not @lecture1.valid?
		assert_equal [:course, :group, :name, :url, :appearance_time, :due_date, :course_id, :group_id, :start_time, :end_time, :duration, :position ], @lecture1.errors.keys
		@lecture1.name = 'name'
		@lecture1.course_id = @course1.id
		@lecture1.group_id = @group1.id
		@lecture1.url = "http://www.youtube.com/watch?v=xGcG4cp2yzY"
		@lecture1.start_time = 0
		@lecture1.end_time = 240
		@lecture1.duration = 240
		@lecture1.appearance_time_module = true 
		@lecture1.due_date_module = true
		@lecture1.position = 1

		@lecture1.appearance_time = '2017-9-9'.to_datetime
		@lecture1.due_date = '2017-8-9'.to_datetime
		assert_not @lecture1.valid?
		assert_equal [:due_date ], @lecture1.errors.keys
		@lecture1.due_date = '2017-10-9'.to_datetime
		assert @lecture1.valid?
		assert @lecture1.save

		# ## validate the appearance date is before the items appearance date

		@lecture1.appearance_time = '2017-9-8'.to_datetime
		assert_not @lecture1.valid?
		assert_equal [:appearance_time ], @lecture1.errors.keys

		@lecture1.appearance_time = '2017-9-9'.to_datetime
		@lecture1.due_date = '2017-10-10'.to_datetime
		assert_not @lecture1.valid?
		assert_equal [:due_date ], @lecture1.errors.keys

		@lecture1.due_date = '2017-10-9'.to_datetime
		assert @lecture1.valid?

		@lecture1.inclass = true
		assert @lecture1.valid?

		@lecture1.distance_peer = true
		assert_not @lecture1.valid?

		assert_equal [:distance_peer ], @lecture1.errors.keys

		@lecture1.inclass = false
		@lecture1.distance_peer = false
		assert @lecture1.valid?
		# ## validate the due date is after the items due date
	end

end
