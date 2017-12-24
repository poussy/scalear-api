class OnlineQuiz < ApplicationRecord
	
	has_many :online_answers, -> { order('id') }, :dependent => :destroy
	has_many :online_quiz_grades , :dependent => :destroy
	has_many :free_online_quiz_grades , :dependent => :destroy
	has_many :user_distance_peers, :dependent => :destroy

	has_one :inclass_session, :dependent => :destroy
	belongs_to :lecture, :touch => true
	belongs_to :group
	belongs_to :course

	validates :time,:start_time, :end_time,:lecture_id,:question,  :intro, :self, :in_group, :discussion, :presence => true

	attribute :match_type
	attribute :solved_quiz
	attribute :reviewed
	attribute :votes_count
	attribute :online_answers
	attribute :online_answers_drag
	attribute :inclass_session

	# def formatted_time
	# end

	# def is_quiz_solved
	# end

	def get_votes
		if self.question_type.upcase=="DRAG" || self.question_type.upcase=="FREE TEXT QUESTION"
			return self.free_online_quiz_grades.where(:attempt=>1).select{|grade| grade.review_vote }.map{|a| a.user_id}.uniq.count
		else
			return self.online_quiz_grades.where(:attempt=>1).select{|grade| grade.review_vote}.map{|a| a.user_id}.uniq.count
		end		
	end

	def get_chart(students_id)
		data={}
		quiz = self
		# students_count = self.course.enrollments.count
		students_count = students_id.size

		if quiz.question_type=="OCQ" || quiz.question_type=="MCQ"
			# quiz.online_answers.each do |answer|
			#   answer_color = answer.correct ? "green" : "gray"
			#   answers_count = self.online_quiz_grades.where(:online_answer_id => answer.id, :attempt => 1).group(:in_group).count
			#   data[answer.id] = [answers_count[false], answer_color, answer.answer, answers_count[true]]
			# end
			if quiz.quiz_type.include?("survey")
					# user_ids_attempt_online_answers  = quiz.online_quiz_grades.group(:user_id ).select('user_id as user_id , Max(attempt) as max').map{|a| [a.user_id ,  a.max.to_i ] }
					s_g_user_id_max = {}
					s_g_online_answer_raw = quiz.online_quiz_grades.group(:user_id , :in_group ).select('user_id as user_id, in_group as in_group , Max(attempt) as max').group_by{|a| a.in_group}
					s_g_online_answer_raw.each{|a| s_g_user_id_max[a[0]] = a[1].map{|a| [a.user_id ,  a.max.to_i ] }}

					# online_answers_list = quiz.online_quiz_grades.select{|a| user_ids_attempt_online_answers.include?([a.user_id , a.attempt.to_i]) }.map{|a| a.online_answer_id} || []
					s_g_answer_list = {}
					s_g_user_id_max.each{|answer_type| s_g_answer_list[answer_type[0]] =  quiz.online_quiz_grades.select{|a| answer_type[1].include?([a.user_id , a.attempt.to_i]) }.map{|a| a.online_answer_id} || []  }
			end
			quiz.online_answers.each do |answer|

					grade_grouped_user_ids_list = {}
					answer.online_quiz_grades.select{|a| students_id.include?(a.user_id) }.group_by{ |quiz_grade| [quiz_grade.attempt == 1 , quiz_grade.in_group]  }.each{|quiz_grade_group| grade_grouped_user_ids_list[quiz_grade_group[0]] =  quiz_grade_group[1].map{|e| e.user_id }.uniq  }
					# answer.free_online_quiz_grades.group_by{ |quiz_grade| quiz_grade.attempt == 1 }.each{|quiz_grade_group| grade_grouped_user_ids_list[quiz_grade_group[0]] =  quiz_grade_group[1].map{|e| e.user_id }.uniq  }

					max_attempt_ids = []
					if answer.correct
							first_try_color = "green"
							self_first_try_grades_count = (grade_grouped_user_ids_list[[true,false]]|| []).size
							not_self_first_try_grades_count = ( (grade_grouped_user_ids_list[[false,false]] || []) - (grade_grouped_user_ids_list[[true,false]] || []) ).uniq.size
							group_first_try_grades_count = (grade_grouped_user_ids_list[[true,true]]|| []).size
							not_group_first_try_grades_count = ( (grade_grouped_user_ids_list[[false,true]] || []) - (grade_grouped_user_ids_list[[true,true]] || []) ).uniq.size
					else
							if quiz.quiz_type.include?("survey")# survey
									first_try_color = 'blue'
									self_first_try_grades_count = (s_g_answer_list[false] || []).count(answer.id)
									not_self_first_try_grades_count = 0
									group_first_try_grades_count = (s_g_answer_list[true] || []).count(answer.id)
									not_group_first_try_grades_count = 0
							else
									first_try_color = "orange"
									not_self_first_try_grades_count = ( grade_grouped_user_ids_list[[false,false]] || [] ).uniq.size
									self_first_try_grades_count = ( (grade_grouped_user_ids_list[[true,false]] || []) - (grade_grouped_user_ids_list[[false,false]]|| []) ).uniq.size
									group_first_try_grades_count = (grade_grouped_user_ids_list[[true,true]]|| []).size
									not_group_first_try_grades_count = ( (grade_grouped_user_ids_list[[false,true]] || []) - (grade_grouped_user_ids_list[[true,true]] || []) ).uniq.size
							end
					end
					data[answer.id]= [self_first_try_grades_count, first_try_color, answer.answer , not_self_first_try_grades_count, group_first_try_grades_count, not_group_first_try_grades_count]
			end
			# did_not_try_count  = students_count - (quiz.online_quiz_grades.map{|e| e.user_id }.uniq.count)
			did_not_user_ids_list = {}
			quiz.online_quiz_grades.select{|a| students_id.include?(a.user_id) }.group_by{ |quiz_grade| quiz_grade.in_group }.each{|quiz_grade_group| did_not_user_ids_list[quiz_grade_group[0]] =  quiz_grade_group[1].map{|e| e.user_id }.uniq  }
			if quiz.online_answers
					last_id = quiz.online_answers.last.id + 1
					self_did_not_try_count = students_count - (did_not_user_ids_list[false] || []).count
					group_did_not_try_count = students_count - (did_not_user_ids_list[true] || []).count
					data[last_id]= [ self_did_not_try_count , 'gray', "Never tried",0, group_did_not_try_count ]
			end




		elsif quiz.question_type.downcase=="drag" and quiz.quiz_type=="html" #drag and html

			correct_answer=[]
			correct_answer=quiz.online_answers.first.answer  if quiz.online_answers.size!=0#[1,2,3]
			tried_correct_ids_count = quiz.free_online_quiz_grades.select{ |quiz_grade| quiz_grade.grade }.map{|e| e.user_id }.uniq.size
			quiz.free_online_quiz_grades.order(:attempt).select{|grade| students_id.include?(grade.user_id) }.each do |u|
					# correct_first_ids = []
					correct_answer.each_with_index do |answer_text,index|
							data[answer_text]=[0,"green","#{answer_text} in correct place",0] if data[answer_text].nil?
							if answer_text==u.online_answer[index] && u.attempt == 1
									data[answer_text][0]+=1 # [ (data[e][0]||0) + 1, "green", "#{e} in correct place"]
							end
							data[answer_text][3] = tried_correct_ids_count - data[answer_text][0] # [ (data[e][0]||0) + 1, "green", "#{e} in correct place"]
					end
			end
			did_not_try_count  = students_count - (quiz.free_online_quiz_grades.map{|e| e.user_id }.uniq.count)
			if quiz.online_answers
					data['~']= [ did_not_try_count , 'gray', "Never tried" ]
			end

		else #drag and invideo

			quiz.online_answers.each do |answer|
					grade_grouped_user_ids_list = {}
					answer.online_quiz_grades.select{|grade| students_id.include?(grade.user_id) &&  grade.optional_text == answer.answer }.group_by{ |quiz_grade| quiz_grade.attempt == 1  }.each{|quiz_grade_group| grade_grouped_user_ids_list[quiz_grade_group[0]] =  quiz_grade_group[1].map{|e| e.user_id }.uniq  }
					max_attempt_ids = []

					first_try_color = "green"
					first_try_grades_count = (grade_grouped_user_ids_list[true]|| []).size
					not_first_try_grades_count = ( (grade_grouped_user_ids_list[false] || []) - (grade_grouped_user_ids_list[true] || []) ).uniq.size

					data[answer.id]= [first_try_grades_count, first_try_color, answer.answer , not_first_try_grades_count]
					did_not_try_count = first_try_grades_count + not_first_try_grades_count
			end

			if quiz.online_answers
					did_not_try_count  = students_count - did_not_try_count
					last_id = quiz.online_answers.last.id + 1
					data[last_id]= [ did_not_try_count , 'gray', "Never tried" ]
			end

		end
		return data
	end

end