class Lecture < ApplicationRecord
	belongs_to :course, :touch => true
	belongs_to :group, :touch => true
	has_many :assignment_item_statuses, :dependent => :destroy
	has_many :confuseds, :dependent => :destroy
	has_many :distance_peers
	has_many :events
	has_many :free_online_quiz_grades
	has_many :inclass_sessions, :dependent => :destroy
	has_many :lecture_views, :dependent => :destroy
	has_many :online_markers, -> { order('time') }, :dependent => :destroy
	has_many :online_quiz_grades, :dependent => :destroy
	has_many :online_quizzes, -> { order('time') }, :dependent => :destroy
	has_many :video_events, :dependent => :destroy
	has_many :video_notes, :dependent => :destroy
		

	validates :name, :url,:appearance_time, :due_date,:course_id, :group_id, :start_time, :end_time, :position, :presence => true
	validates_inclusion_of :appearance_time_module, :due_date_module,:required_module , :graded_module, :inclass, :distance_peer, :in => [true, false] #not in presence because boolean false considered not present.

	validates_datetime :appearance_time, :on_or_after => lambda{|m| m.group.appearance_time}, :on_or_after_message => I18n.t("lectures.errors.appearance_time_after_module_appearance_time")

	validates_datetime :due_date, :on_or_after => lambda{|m| m.appearance_time}, :on_or_after_message => I18n.t("lectures.errors.due_date_pass_after_appearance_date")

	# validates_datetime :due_date, :on_or_before => lambda{|m| m.group.due_date}, :on_or_before_message => "must be before module due date"
	validate :due_before_module_due_date
	validate :type_inclass_distance_peer

	attr_accessor :current_user

	attribute :class_name
	attribute :done
	attribute :user_confused
	attribute :posts
	attribute :lecture_notes
	attribute :title_markers
	attribute :video_quizzes
	attribute :annotations


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

	def is_done
		assign= current_user.get_assignment_status(self)
		assign_lecture = current_user.get_lecture_status(self)
		if (!assign.nil? && assign.status==1) || (!assign_lecture.nil? && assign_lecture.status==1)#modified status and marked as done on time
			return true
		else
			lecture_quizzes=online_quizzes.includes(:online_answers).select{|f| f.online_answers.size!=0 && f.graded}.map{|v| v.id}.sort #ids of lecture quizzes
			user_quizzes=current_user.get_online_quizzes_solved(self)   #stubbed in lec_spec
			#will add now the marks.
			viewed=current_user.get_lectures_viewed(self)
			return ( user_quizzes&lecture_quizzes == lecture_quizzes and !viewed.empty? and viewed.first.percent == 100)
		end
  	end

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
			errors.add(:due_date, I18n.t("lectures.errors.time_before_module_due_date") )
		end
	end

	def type_inclass_distance_peer
		if (self.distance_peer && self.inclass )
			errors.add(:distance_peer, I18n.t("lectures.errors.inclass_distance_peer_both_true") )
		end
	end

	def clean_up
		self.events.where(:quiz_id => nil).destroy_all
	end

end