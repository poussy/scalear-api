require 'test_helper'

class GroupsControllerTest < ActionDispatch::IntegrationTest
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

		@group1 = Group.new 
		@group1.name = 'name'
		@group1.course_id = @course1.id
		@group1.appearance_time = '2017-9-9'.to_datetime
		@group1.due_date = '2017-10-9'.to_datetime
		@group1.graded = false
		@group1.required = false
		assert @group1.valid?
		@group1.save
		assert Group.count == 1

		@group2 = Group.new 
		@group2.name = 'name'
		@group2.course_id = @course2.id
		@group2.appearance_time = '2017-9-9'.to_datetime
		@group2.due_date = '2017-10-9'.to_datetime
		@group2.graded = false
		@group2.required = false
		assert @group2.valid?
		@group2.save
		assert Group.count == 2
	end

	test "Validate Cancancancan.. abilities" do

		ability1 = Ability.new(@user1)
		assert ability1.can?(:create, Group)
		assert ability1.can?(:destroy, @group1)
		assert ability1.cannot?(:destroy, @group2)
		assert ability1.can?(:get_module_summary, @group1)

		ability2 = Ability.new(@user2)
		assert ability2.can?(:create, Group)

		assert ability2.cannot?(:destroy, @group1)
		assert ability2.can?(:destroy, @group2)

		assert ability2.can?(:get_module_summary, @group2)

		@course1.add_professor(@user2 , false)
		assert ability2.can?(:get_module_charts_angular, @group1)
		assert ability2.can?(:get_module_charts_angular, @group2)

	end
end
