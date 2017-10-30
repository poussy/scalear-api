require 'test_helper'

class CoursesControllerTest < ActionDispatch::IntegrationTest
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

	test "Validate Cancancancan.. abilities" do
		ability1 = Ability.new(@user1)
		assert ability1.can?(:create, Course)
		assert ability1.can?(:destroy, @course1)
		assert ability1.cannot?(:destroy, @course2)
		assert ability1.can?(:teachers, @course1)
		assert ability1.cannot?(:getCourse, @course1)

		ability2 = Ability.new(@user2)
		assert ability2.can?(:create, Course)

		assert ability2.cannot?(:destroy, @course1)
		assert ability2.can?(:destroy, @course2)

		assert ability2.can?(:teachers, @course2)
		assert ability2.cannot?(:getCourse, @course2)

		@course1.add_professor(@user2 , false)
		assert ability2.can?(:destroy, @course1)
		assert ability2.can?(:destroy, @course2)
	end
end
