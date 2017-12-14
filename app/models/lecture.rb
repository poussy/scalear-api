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
	attribute :requirements


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

	def get_questions
		data={}
			online_quizzes.select{|f| !f.online_answers.empty?}.each do |quiz|
				data[quiz.id] = {:title => quiz.question, :time => quiz.time, :type => quiz.question_type, :quiz_type => quiz.quiz_type, :review => quiz.get_votes, :inclass => quiz.inclass}
			end
		return data
	end

	# def get_questions_visible
	# end

	# def get_question_ids
	# end

	def get_checked_quizzes
		data={}
		self.online_quizzes.select{|f| !f.online_answers.empty?}.each do |quiz|
			data[quiz.id] = quiz.hide
		end
		return data
	end

	# def convert_short_to_long_url
	# end

	def get_charts_all(students_id)
			online_q= self.online_quizzes
			return get_charts(students_id ,online_q)
	end

	# def get_charts_visible(students_id)
	# end

	# def get_charts_all(students_id)
	# end

	def get_charts(students_id,online_q)
		data={}
		students_count = students_id.size
		# online_q = self.online_quizzes.select{|f| !f.online_answers.empty?}
		online_q.each do |quiz|
			data[quiz.id]={}
			if self.distance_peer || self.inclass
				data[quiz.id] =  OnlineQuiz.find(quiz.id).get_chart(students_id)
			else
				if quiz.question_type=="OCQ" || quiz.question_type=="MCQ"
					if quiz.quiz_type.include?("survey")
						user_ids_attempt_online_answers  = quiz.online_quiz_grades.group(:user_id ).select('user_id as user_id , Max(attempt) as max').map{|a| [a.user_id ,  a.max.to_i ] }
						online_answers_list = quiz.online_quiz_grades.select{|a| user_ids_attempt_online_answers.include?([a.user_id , a.attempt.to_i]) }.map{|a| a.online_answer_id} || []
					end
					quiz.online_answers.each do |answer|
						grade_grouped_user_ids_list = {}
						answer.online_quiz_grades.select{|a| students_id.include?(a.user_id) }.group_by{ |quiz_grade| quiz_grade.attempt == 1  }.each{|quiz_grade_group| grade_grouped_user_ids_list[quiz_grade_group[0]] =  quiz_grade_group[1].map{|e| e.user_id }.uniq  }
						# answer.free_online_quiz_grades.group_by{ |quiz_grade| quiz_grade.attempt == 1 }.each{|quiz_grade_group| grade_grouped_user_ids_list[quiz_grade_group[0]] =  quiz_grade_group[1].map{|e| e.user_id }.uniq  }

						max_attempt_ids = []
						if answer.correct
								first_try_color = "green"
								first_try_grades_count = (grade_grouped_user_ids_list[true]|| []).size
								not_first_try_grades_count = ( (grade_grouped_user_ids_list[false] || []) - (grade_grouped_user_ids_list[true] || []) ).uniq.size
						else
								if quiz.quiz_type.include?("survey")# survey
									first_try_color = 'blue'
									first_try_grades_count = online_answers_list.count(answer.id)
								else
									first_try_color = "orange"
									not_first_try_grades_count = ( grade_grouped_user_ids_list[false] || [] ).uniq.size
									first_try_grades_count = ( (grade_grouped_user_ids_list[true] || []) - (grade_grouped_user_ids_list[false]|| []) ).uniq.size
								end
						end
						data[quiz.id][answer.id]= [first_try_grades_count, first_try_color, answer.answer , not_first_try_grades_count]
					end
					did_not_try_count  = students_count - (quiz.online_quiz_grades.select{|a| students_id.include?(a.user_id)}.map{|e| e.user_id }.uniq.count)
					if quiz.online_answers.size > 0
						last_id = quiz.online_answers.last.id + 1
						data[quiz.id][last_id]= [ did_not_try_count , 'gray', "Never tried" ]
					end
				elsif quiz.question_type.downcase=="drag" and quiz.quiz_type=="html" #drag and html

					correct_answer=[]
					correct_answer=quiz.online_answers.first.answer  if quiz.online_answers.size!=0#[1,2,3]

					tried_correct_ids_count = quiz.free_online_quiz_grades.select{ |quiz_grade| quiz_grade.grade }.map{|e| e.user_id }.uniq.size

					quiz.free_online_quiz_grades.order(:attempt).select{|grade| students_id.include?(grade.user_id) }.each do |u|
							# correct_first_ids = []

						correct_answer.each_with_index do |answer_text,index|
							data[quiz.id][answer_text]=[0,"green","#{answer_text} in correct place",0] if data[quiz.id][answer_text].nil?
							if answer_text==u.online_answer[index] && u.attempt == 1
								data[quiz.id][answer_text][0]+=1 # [ (data[quiz.id][e][0]||0) + 1, "green", "#{e} in correct place"]
							end
							data[quiz.id][answer_text][3] = tried_correct_ids_count - data[quiz.id][answer_text][0] # [ (data[quiz.id][e][0]||0) + 1, "green", "#{e} in correct place"]
						end
					end
					did_not_try_count  = students_count - (quiz.free_online_quiz_grades.map{|e| e.user_id }.uniq.count)
					if quiz.online_answers.size > 0
						data[quiz.id]['~']= [ did_not_try_count , 'gray', "Never tried" ]
					end

				else #drag and invideo
					quiz.online_answers.each do |answer|
						grade_grouped_user_ids_list = {}
						answer.online_quiz_grades.select{|grade| students_id.include?(grade.user_id) &&  grade.optional_text == answer.answer }.group_by{ |quiz_grade| quiz_grade.attempt == 1  }.each{|quiz_grade_group| grade_grouped_user_ids_list[quiz_grade_group[0]] =  quiz_grade_group[1].map{|e| e.user_id }.uniq  }
						max_attempt_ids = []

						first_try_color = "green"
						first_try_grades_count = (grade_grouped_user_ids_list[true]|| []).size
						not_first_try_grades_count = ( (grade_grouped_user_ids_list[false] || []) - (grade_grouped_user_ids_list[true] || []) ).uniq.size

						data[quiz.id][answer.id]= [first_try_grades_count, first_try_color, answer.answer , not_first_try_grades_count]
						did_not_try_count = first_try_grades_count + not_first_try_grades_count
					end

					if quiz.online_answers.size > 0
						did_not_try_count  = students_count - (quiz.online_quiz_grades.map{|e| e.user_id }.uniq.count)
						last_id = quiz.online_answers.last.id + 1
						data[quiz.id][last_id]= [ did_not_try_count , 'gray', "Never tried" ]
					end
				end
			# else #distance_pper lecture
			end
		end
		return data
	end

	def get_statistics(students)
		students_id = students.map(&:id)
		confuseds={}   #{234 => [23,"http://sss"]} # cumulative_time => [real_time, url]
		really_confuseds={}
		discussion={}
		confuseds = self.confuseds.where(:very => false, :user_id =>  students_id).order('time ASC').select([:time, :hide])
		really_confuseds = self.confuseds.where(:very => true, :user_id =>  students_id).order('time ASC').select([:time, :hide])

		posts = Forum::Post.find(:all, :params => {lecture_id: self.id}).select{|p| students_id.include?(p.user_id)}
		posts.each do |p|
			user = students.select{|s| s.id == p.user_id}.first
			user = User.new(:screen_name => "missing", :email => "missing")  if user.nil?
			p.email = user.email
			p.screen_name = user.screen_name
			p.comments = p.comments_all()
		end

		return {:confused => confuseds,:really_confused => really_confuseds, :discussion => posts}
	end

	# def get_free_text_answers
	# end

	# def get_visible_free_text
	# end

	# def get_free_text_questions
	# end

	def get_free_text_question_and_answers(students_id)
		data = {}
		self.online_quizzes.select{|v| v.question_type == 'Free Text Question'}.each do |quiz|
			data[quiz.id] = {}
			data[quiz.id][:question] = {:title => quiz.question, :hide => quiz.hide, :time => quiz.time, :review => quiz.get_votes}
			data[quiz.id][:answer] = quiz.free_online_quiz_grades.select{|grade| grade.online_answer != '' && students_id.include?(grade.user_id) }
		end
		return data
	end

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