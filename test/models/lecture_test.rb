require 'test_helper'

class LectureTest < ActiveSupport::TestCase
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
		lecture1 = Lecture.new 
		assert_not lecture1.valid?
		assert_equal [:course, :group, :name, :url, :appearance_time, :due_date, :course_id, :group_id, :start_time, :end_time, :position ], lecture1.errors.keys
		lecture1.name = 'name'
		lecture1.course_id = @course1.id
		lecture1.group_id = @group1.id
		lecture1.url = "http://www.youtube.com/watch?v=xGcG4cp2yzY"
		lecture1.start_time = 0
		lecture1.end_time = 240
		lecture1.duration = 240
		lecture1.appearance_time_module = true 
		lecture1.due_date_module = true
		lecture1.position = 1

		lecture1.appearance_time = '2017-9-9'.to_datetime
		lecture1.due_date = '2017-8-9'.to_datetime
		assert_not lecture1.valid?
		assert_equal [:due_date ], lecture1.errors.keys
		lecture1.due_date = '2017-10-9'.to_datetime
		assert lecture1.valid?
		assert lecture1.save

		lecture1.inclass = true
		assert lecture1.valid?

		lecture1.distance_peer = true
		assert_not lecture1.valid?

		assert_equal [:distance_peer ], lecture1.errors.keys

		lecture1.inclass = false
		lecture1.distance_peer = false
		assert lecture1.valid?

	end

		# ## validate the appearance date is before the items appearance date
	test "validate Lecture appearance_time & due_date within group appearance_time & due_date" do
		@lecture1.appearance_time = '2017-9-8'.to_datetime
		assert_not @lecture1.valid?
		assert_equal [:appearance_time ], @lecture1.errors.keys

		@lecture1.appearance_time = '2017-9-9'.to_datetime
		@lecture1.due_date = '2017-10-10'.to_datetime
		assert_not @lecture1.valid?
		assert_equal [:due_date ], @lecture1.errors.keys

		@lecture1.due_date = '2017-10-9'.to_datetime
		assert @lecture1.valid?

	end

end
