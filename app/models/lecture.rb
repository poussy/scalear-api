class Lecture < ApplicationRecord
	belongs_to :course, :touch => true
	belongs_to :group, :touch => true
	has_many :assignment_item_statuses, :dependent => :destroy

	validates :name, :url,:appearance_time, :due_date,:course_id, :group_id, :start_time, :end_time, :position, :presence => true
	validates_inclusion_of :appearance_time_module, :due_date_module,:required_module , :graded_module, :inclass, :distance_peer, :in => [true, false] #not in presence because boolean false considered not present.

	validates_datetime :appearance_time, :on_or_after => lambda{|m| m.group.appearance_time}, :on_or_after_message => "lecture.errors.appearance time_after_module_appearance_time"

	validates_datetime :due_date, :on_or_after => lambda{|m| m.appearance_time}, :on_or_after_message => "lecture.errors.due_date_pass_after_appearance_date"

	# validates_datetime :due_date, :on_or_before => lambda{|m| m.group.due_date}, :on_or_before_message => "must be before module due date"
	validate :due_before_module_due_date
	validate :type_inclass_distance_peer

	attribute :class_name
	attribute :className



	# def has_not_appeared
	# end

	# def get_class_name
	# end

	# def current_confused
	# end

	# def cumulative_duration
	# end

	# def notes
	# end

	# def annotated_markers
	# end

	# def titled_markers
	# end

	# def posts_public
	# end

	# def posts_all
	# end

	# def posts_all_teacher
	# end

	# def done?(user_asking) #marks lecture as done IF all quizzes solved AND passed all 25/50/75 marks.
	# end

	# def is_done
	# end

	# def is_done_summary_table
	# end

	# def is_done_user(st)
	# end

	# def is_done?(user_asking) #marks lecture as done IF all quizzes solved AND passed all 25/50/75 marks.
	# end

	# def get_data
	# end

	# def get_colors
	# end

	# def get_categories
	# end

	# def get_questions
	# end

	# def get_questions_visible
	# end

	# def get_question_ids
	# end

	# def get_checked_quizzes
	# end

	# def convert_short_to_long_url
	# end

	# def get_charts_all
	# end

	# def get_charts_visible(students_id)
	# end

	# def get_charts_all(students_id)
	# end

	# def get_charts(students_id,online_q)
	# end

	# def get_statistics(students)
	# end

	# def get_free_text_answers
	# end

	# def get_visible_free_text
	# end

	# def get_free_text_questions
	# end

	# def get_free_text_question_and_answers(students_id)
	# end

  private
	def due_before_module_due_date
		if self.due_date && self.due_date > self.group.due_date && self.due_date < (Time.now + 100.years)
			errors.add(:due_date, "lecture.errors.time_before_module_due_date")
		end
	end

	def type_inclass_distance_peer
		if (self.distance_peer && self.inclass )
			errors.add(:distance_peer, "lecture.errors.inclass_distance_peer_both_true")
		end
	end

	def clean_up
			### waiting for add events table 
			# self.events.where(:quiz_id => nil).destroy_all
	end

end