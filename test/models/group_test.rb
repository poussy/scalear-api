require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
	def setup
		@user1 = users(:user1)
		@course1 = courses(:course1)
		@group1 = groups(:group1)
		@lecture1 = lectures(:lecture1)
	end

	test "Validate model validation" do
		group1 = Group.new 
		assert_not group1.valid?
		assert_equal [:course, :appearance_time, :course_id, :name, :due_date, :position, :skip_ahead ], group1.errors.keys
		group1.name = 'name'
		group1.position = 1
		group1.course_id = @course1.id

		group1.appearance_time = '2017-9-9'.to_datetime
		group1.due_date = '2017-8-9'.to_datetime
		assert_not group1.valid?

		assert_equal [ :skip_ahead,:due_date ], group1.errors.keys
		assert_not group1.valid?

		group1.due_date = '2017-10-9'.to_datetime
		group1.skip_ahead = true
		assert group1.valid?
		group1.save

	end

	test "validate Lecture appearance_time & due_date within group appearance_time & due_date" do
		# # ## validate the appearance date is before the items appearance date
		@lecture1.appearance_time_module = false
		@lecture1.due_date_module = false
		@lecture1.save
		@group1.appearance_time = '2017-9-18'.to_datetime
		assert_not @group1.valid?
		assert_equal [ :appearance_dates ], @group1.errors.keys

		# # ## validate the due date is after the items due date
		@group1.appearance_time = '2017-9-9'.to_datetime
		@group1.due_date = '2017-9-18'.to_datetime
		assert_not @group1.valid?
		assert_equal [ :due_date ], @group1.errors.keys

		# @group1.appearance_time = '2017-9-9'.to_datetime
		@group1.due_date = '2017-10-9'.to_datetime
		assert @group1.valid?

	end

end
