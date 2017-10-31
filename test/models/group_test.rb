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

		@course1 = Course.new ({name: 'name' , short_name: 'short_name' , user_id: @user1.id , time_zone: "time_zone" , start_date: '2017-9-4'.to_datetime , end_date: '2017-10-9'.to_datetime , image_url: 'https://pbs.twimg.com/profile_images/839721704163155970/LI_TRk1z_400x400.jpg' })
		assert @course1.valid?

		@course1.save
		@course1.add_professor(@user1 , false)

		@course2 = Course.new ({name: 'name' , short_name: 'short_name' , user_id: @user2.id , time_zone: "time_zone" , start_date: '2017-9-4'.to_datetime , end_date: '2017-10-9'.to_datetime , image_url: 'https://pbs.twimg.com/profile_images/839721704163155970/LI_TRk1z_400x400.jpg' })
		assert @course2.valid?
		@course2.save
		@course2.add_professor(@user2 , false)

	end

	test "Validate model validation" do
		@group1 = Group.new 
		assert_not @group1.valid?
		assert_equal [:course, :appearance_time, :course_id, :name, :due_date, :position ], @group1.errors.keys
		@group1.name = 'name'
		@group1.position = 1
		@group1.course_id = @course1.id
		# course.end_date = 'time_zone'
		# assert_not course.valid?
		# assert_equal [ :end_date,  :start_date], course.errors.keys

		@group1.appearance_time = '2017-9-9'.to_datetime
		@group1.due_date = '2017-8-9'.to_datetime
		assert_not @group1.valid?

		assert_equal [ :due_date ], @group1.errors.keys
		assert_not @group1.valid?

		@group1.due_date = '2017-10-9'.to_datetime
		assert @group1.valid?
		@group1.save
		assert Group.count == 1

		@lecture1 = Lecture.new({name:'name' , url: "http://www.youtube.com/watch?v=xGcG4cp2yzY", start_time: 0 ,end_time: 240 ,duration: 240 ,position: 1 ,appearance_time_module: false  ,due_date_module: false })
		# @lecture1.course_id = @course1.id
		@group1.lectures << @lecture1 
		@course1.lectures << @lecture1 
		
		@lecture1.appearance_time = '2017-9-9'.to_datetime
		@lecture1.due_date = '2017-10-9'.to_datetime

		assert @lecture1.valid?

		@lecture1.save

		assert Lecture.count == 1

		# # ## validate the appearance date is before the items appearance date
		@group1.appearance_time = '2017-9-18'.to_datetime
		assert_not @group1.valid?
		assert_equal [ :appearance_time ], @group1.errors.keys

		# # ## validate the due date is after the items due date
		@group1.appearance_time = '2017-9-9'.to_datetime
		@group1.due_date = '2017-9-18'.to_datetime
		assert_not @group1.valid?
		assert_equal [ :due_date ], @group1.errors.keys

		@lecture1.appearance_time = '2017-9-9'.to_datetime
		@lecture1.due_date = '2017-10-9'.to_datetime
		assert @lecture1.valid?

	end




end