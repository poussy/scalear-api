class Group < ApplicationRecord
	belongs_to :course, :touch => true
	
	has_many :lectures, -> { order('position') }, :dependent => :destroy
	has_many :quizzes, -> { order('position') }, :dependent => :destroy 
	has_many :custom_links, -> { order('position') }, :dependent => :destroy

	after_destroy :clean_up

	validates :appearance_time, :course_id, :name, :due_date, :position , :presence => true
	validates_inclusion_of :graded , :required, :in => [true, false] #not in presence because boolean false considered not present.

	@quiz_not_empty = Proc.new{|f| !f.online_answers.empty? or f.question_type=="Free Text Question"}
	
	validate :appearance_date_must_be_before_items
	validate :due_date_must_be_after_items
	validates_datetime :due_date, :on_or_after => lambda{|m| m.appearance_time}, :on_or_after_message => "group.errors.due_date_pass_after_appearance_date"

	# def has_not_appeared
	# end

	# def has_appeared
	# end

	# def was_late?(grades)
	# end

	# def copy_group(course_to_copy_to)
	# end

	# def get_stats
	# end

	# def get_stats_summary#[not_watched, watched_less_than_50, watched_more_than_50, watched_more_than_80, completed_on_time, completed_late]
	# end

	# def get_numbering
	# end

	# def get_data_percent
	# end

	# def get_colors
	# end

	# def get_categories
	# end

	# def get_lecture_names
	# end

	# def get_questions
	# end

	# def get_question_ids
	# end

	# def get_checked_quizzes
	# end

	# def total_questions
	# end

	# def total_questions_display
	# end

	# def total_quiz_questions #doesn't count survey questions.
	# end

	# def total_survey_questions #doesn't count survey questions.
	# end

	# def total_time
	# end

	# def get_items_json
	# end

	# def get_items
	# end

	# def get_sub_items
	# end

	# def get_appeared_items
	# end

	# def get_lecture_list
	# end

	# def get_display_data
	# end

	# def get_display_question_data
	# end

	# def total_student_questions
	# end

	# def total_student_questions_review
	# end

	# def next_item(pos)
	# end

	# def next_lecture(lec_pos)
	# end

	# def previous_lecture(lec_pos)
	# end

	# def get_statistics
	# end

	# def inclass_session
	# end

	# def get_module_summary_teacher
	# end

	# def get_summary_teacher_for_each_online_quiz(online_quiz , students_count)
	# end

	# def get_summary_teacher_for_each_normal_quiz(question , students_count)
	# end

	# def get_online_quiz_summary_teacher
	# end


	# def get_discussion_summary_teacher
	# end

	# def get_module_summary_student(current_user)
	# end

	# def get_completion_summary_student(current_user)
	# end

	# def get_discussion_summary_student(current_user)
	# end

	private

		# def validate_due_date_after_appearance_time
		# 	if due_date && appearance_time && due_date < appearance_time
		# 		errors.add(:due_date, "group.errors.due_date_pass")
		# 	end
		# end

		def appearance_date_must_be_before_items
			error=false
			lectures.each do |l|
				if l.appearance_time < appearance_time and l.appearance_time_module==false
					error=true
				end
			end
			errors.add(:appearance_time, "group.errors.appearance_date_must_be_before_items") if error		
			# errors.add(:appearance_time, "must be before items appearance time") if error		
		end
		
		def due_date_must_be_after_items
			error=false
			(lectures+quizzes).each do |l|
				if l.due_date > due_date and l.due_date_module==false and l.due_date < (Time.now + 100.years)
					error=true
				end
			end
			errors.add(:due_date, "group.errors.due_date_must_be_after_items") if error
		end

		def clean_up
			### change after add events to the 
			# self.events.where(:lecture_id => nil, :quiz_id => nil).destroy_all
			p "Events destroyed"
		end
end