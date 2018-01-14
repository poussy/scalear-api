class Group < ApplicationRecord
	belongs_to :course, :touch => true
	
	has_many :lectures, -> { order('position') }, :dependent => :destroy
	has_many :quizzes, -> { order('position') }, :dependent => :destroy 
	has_many :custom_links, -> { order('position') }, :dependent => :destroy
	has_many :quiz_statuses
	has_many :assignment_statuses, :dependent => :destroy
	has_many :assignment_item_statuses, :dependent => :destroy
	has_many :distance_peers, :dependent => :destroy
	has_many :events
	has_many :free_online_quiz_grades
	has_many :inclass_sessions
	has_many :lecture_views
	has_many :online_markers
	has_many :online_quiz_grades
	has_many :online_quizzes
	has_many :video_events

	after_destroy :clean_up

	validates :appearance_time, :course_id, :name, :due_date, :position , :presence => true
	validates_inclusion_of :graded , :required, :skip_ahead, :in => [true, false] #not in presence because boolean false considered not present.

	@quiz_not_empty = Proc.new{|f| !f.online_answers.empty? or f.question_type=="Free Text Question"}
	
	validate :appearance_date_must_be_before_items
	validate :due_date_must_be_after_items
	validates_datetime :due_date, :on_or_after => lambda{|m| m.appearance_time}, :on_or_after_message => I18n.t("group.errors.due_date_pass_after_appearance_date")

	attribute :total_time 
	attribute :items
	attribute :total_questions
	attribute :total_quiz_questions
	attribute :total_survey_questions
	attribute :total_lectures
	attribute :total_quizzes
	attribute :total_surveys
	attribute :total_links
	attribute :has_inclass
	attribute :has_distance_peer
	attribute :sub_items_size
	attribute :skip_ahead

	attr_accessor :current_user

	# def has_not_appeared
	# end

	# def has_appeared
	# end

	# def was_late?(grades)
	# end

	def copy_group(course_to_copy_to)
      # g is the module i want to copy
      g=self
      new_course= course_to_copy_to
      new_group= g.dup
      new_group.course_id = new_course.id
      new_group.save(:validate => false)
      g.lectures.each do |l|
        new_lecture= l.dup
        new_lecture.course_id = new_course.id
        new_lecture.group_id = new_group.id
        new_lecture.save(:validate => false)
        l.online_quizzes.each do |quiz|
          new_online_quiz = quiz.dup
          new_online_quiz.lecture_id = new_lecture.id
          new_online_quiz.group_id = new_group.id
          new_online_quiz.course_id = new_course.id
          new_online_quiz.save(:validate => false)
          quiz.online_answers.each do |answer|
            new_answer = answer.dup
            new_answer.online_quiz_id = new_online_quiz.id
            new_answer.save(:validate => false)
          end
          quiz_session = quiz.inclass_session
          if !quiz_session.nil?
            new_session = quiz_session.dup
            new_session.online_quiz_id = new_online_quiz.id
            new_session.lecture_id = new_lecture.id
            new_session.group_id = new_group.id
            new_session.course_id = new_course.id
            new_session.save(:validate => false)
          end
        end
        l.online_markers.each do |marker|
          new_online_marker = marker.dup
          new_online_marker.lecture_id = new_lecture.id
          new_online_marker.group_id = new_group.id
          new_online_marker.course_id = new_course.id
          new_online_marker.save(:validate => false)
        end
        Event.where(:quiz_id => nil, :lecture_id => l.id).each do |e|
          new_event= e.dup
          new_event.lecture_id = new_lecture.id
          new_event.course_id = new_course.id
          new_event.group_id = new_group.id
          new_event.save(:validate => false)
        end

      end
      g.quizzes.each do |q|
        new_quiz= q.dup
        new_quiz.course_id = new_course.id
        new_quiz.group_id = new_group.id
        new_quiz.save(:validate => false)
        Event.where(:quiz_id => q.id, :lecture_id => nil).each do |e|
          new_event= e.dup
          new_event.quiz_id = new_quiz.id
          new_event.course_id = new_course.id
          new_event.group_id = new_group.id
          new_event.save(:validate => false)
        end

        q.questions.each do |question|
          new_question = question.dup
          new_question.quiz_id = new_quiz.id
          new_question.save(:validate => false)

          question.answers.each do |answer|
            new_answer = answer.dup
            new_answer.question_id = new_question.id
            new_answer.save(:validate => false)
          end
        end
      end

      g.custom_links.each do |d|
        new_link= d.dup
        new_link.course_id = new_course.id
        new_link.group_id = new_group.id
        new_link.save(:validate => false)
      end
      g.events.where(:quiz_id => nil, :lecture_id => nil).each do |e|
        new_event= e.dup
        new_event.course_id = new_course.id
        new_event.group_id = new_group.id
        new_event.save(:validate => false)
      end

      return new_group
  	end

	# def get_stats
	# end

	def get_stats_summary#[not_watched, watched_less_than_50, watched_more_than_50, watched_more_than_80, completed_on_time, completed_late]
		not_watched=0
		watched_less_than_50=0
		watched_more_than_50=0
		watched_more_than_80 = 0
		completed_on_time=0
		completed_late=0
		self.course.users.each do |u|
			# x=u.grades_module_before_due_date(self)
			x=u.finished_group_percent(self)
			if x==0
					not_watched+=1
			elsif x==1
					watched_more_than_50+=1
			elsif x==2
					completed_on_time+=1
			elsif x==3
					completed_late+=1
			elsif x==4
					watched_less_than_50+=1
			elsif x==5
					watched_more_than_80+=1        
			end
		end
		return [not_watched, watched_less_than_50, watched_more_than_50, watched_more_than_80, completed_on_time, completed_late]
	end

	def survey_count(appearance_time_boolean=false) 
		# return self.quizzes.where(:quiz_type => "survey").count a.appearance_time <= today 
		# .where('start_date <= ?', Time.now) 
		today = Time.now 
		if appearance_time_boolean 
				return self.quizzes.where(:quiz_type => "survey").where('appearance_time <= ?' , today).count 
		else 
				return self.quizzes.where(:quiz_type => "survey").count 
		end 
	end 

	def quiz_count(appearance_time_boolean=false) 
		# return self.quizzes.where(:quiz_type => "quiz").count 
		today = Time.now 
		if appearance_time_boolean 
				return self.quizzes.where(:quiz_type => "quiz").where('appearance_time <= ?' , today).count 
		else 
				return self.quizzes.where(:quiz_type => "quiz").count 
		end 
	end 

	def online_survey_count(appearance_time_boolean=false) 
		search = 'survey' 
		# return self.online_quizzes.where("quiz_type LIKE ?","%#{search}%").count 
		today = Time.now 
		if appearance_time_boolean 
				return (self.online_quizzes.where("quiz_type LIKE ?","%#{search}%")).select{|qu| qu.lecture.appearance_time <= today}.count 
		else 
				return self.online_quizzes.where("quiz_type LIKE ?","%#{search}%").count 
		end 
	end 

	def online_quiz_count(appearance_time_boolean=false) 
		search = 'survey' 
		# return self.online_quizzes.count - self.online_quizzes.where("quiz_type LIKE ?","%#{search}%").count 
		today = Time.now 
		if appearance_time_boolean 
				return (self.online_quizzes - self.online_quizzes.where("quiz_type LIKE ?","%#{search}%")).select{|qu| qu.lecture.appearance_time <= today}.count 
		else  
				return self.online_quizzes.count - self.online_quizzes.where("quiz_type LIKE ?","%#{search}%").count 
		end 
	end 

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

	def total_questions
		count =0
		lectures.each do |l|
			if l.online_quizzes.count != 0
				count+= l.online_quizzes.select(@quiz_not_empty).size
			end
		end
		return count
	end

	# def total_questions_display
	# end

	def total_quiz_questions #doesn't count survey questions.
		count=0;
		quizzes.where("quiz_type!='survey'").each do |q|
			headers_count = q.questions.where(:question_type => 'header').size
			count+= (q.questions.count-headers_count)
		end
		return count
	end

	def total_survey_questions #doesn't count survey questions.
		count=0;
		quizzes.where("quiz_type!='quiz'").each do |q|
			headers_count = q.questions.where(:question_type => 'header').size
			count+= (q.questions.count-headers_count)
		end
		return count
	end

	def total_time
		count=0;
		lectures.each do |l|
			count+=l.duration if !l.duration.nil?
		end
		return count.floor		
	end

	# def get_items_json
	# end

	def get_items
		(quizzes+lectures+custom_links).sort{|a,b| a.position <=> b.position}
	end

	def items
		all = self.get_items
		all.each do |s|
			s[:class_name]= s.class.name.downcase
		end
		return all
	end

	def get_sub_items
    	all=(quizzes+lectures).sort{|a,b| a.position <=> b.position}
	end


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

	def next_item(pos)
		self.get_sub_items.select{|f|
		f.position>pos &&
		(
			(f.class.name.downcase == "lecture" &&
				(!f.inclass ||
					(f.inclass && f.appearance_time <= Time.now)
				)
			) ||
			f.class.name.downcase != "lecture"
		)}.first


  	end

	# def next_lecture(lec_pos)
	# end

	# def previous_lecture(lec_pos)
	# end

	def get_statistics
		confuseds={}   #{234 => [23,"http://sss"]} # cumulative_time => [real_time, url]
		really_confuseds={}
		backs={}
		pauses={}
		discussion={}
		time=0
		time_list={}
		time_list2=[]
		students_id = course.users.map(&:id)
		self.lectures.each do |lec|
			lec.confuseds.select{|v| v.very==false && students_id.include?(v.user_id)}.sort{|x,y| x.time <=> y.time}.each_with_index do |c, index|
				confuseds[[time,c.time, index]] = [c.time, lec.url]
			end
			lec.confuseds.select{|v| v.very==true && students_id.include?(v.user_id)}.sort{|x,y| x.time <=> y.time}.each_with_index do |c, index|
				really_confuseds[[time,c.time, index]] = [c.time, lec.url]
			end
			lec.video_events.where("event_type = 3 and (from_time - to_time) <= 15 and (from_time - to_time) >= 1").sort{|x,y| x.from_time <=> y.from_time}.each_with_index do |c, index|
				backs[[time,c.from_time, index]] = [c.from_time, lec.url]
			end
			lec.video_events.where(:event_type => 2).sort{|x,y| x.from_time <=> y.from_time}.each_with_index do |c, index|
				pauses[[time,c.from_time, index]] = [c.from_time, lec.url]
			end
			posts = Forum::Post.find(:all, :params => {lecture_id: lec.id})

			posts.sort{|x,y| x.time <=> y.time}.each_with_index do |c, index|
				discussion[[time,c.time, index]] = [c.time, c.content, lec.url]
			end

			time+=(lec.duration || 0)
			time_list[time]=lec.url
			time_list2<<[lec.duration,lec.name]

		end
		return [confuseds,backs,pauses,discussion,time, time_list, time_list2, really_confuseds]
  	end


	def inclass_session
			self.inclass_sessions.order("updated_at DESC").first
	end

def get_module_summary_teacher
	course = self.course
	data = {}

	data['title'] = course.short_name+": "+self.name
	data['id'] = self.id
	data['course_id'] = course.id
	data['duration'] = self.lectures.map(&:duration).select{|d| !d.nil?}.sum 
	data['quiz_count'] = self.quizzes.select{|q| q.quiz_type == "quiz"}.size + self.online_quizzes.select{|q| !q.quiz_type.include?"survey" }.size
	data['survey_count'] = self.quizzes.select{|q| q.quiz_type == "survey"}.size +  self.online_quizzes.select{|q| q.quiz_type.include?"survey"}.size
	data['due_date'] = ((self.due_date.to_time - DateTime.current.to_time )) # get due date
	data['due_date_string'] = self.due_date
	data['type'] = "teacher"
	data['students_count'] = course.users.size
	module_stats = self.get_stats_summary #[not_watched, watched_less_than_50, watched_more_than_50, watched_more_than_80,completed_on_time, completed_late]
	data['students_completion'] = {}
	data['students_completion']['incomplete'] = 0 
	data['students_completion']['between_50_80'] = 0 
	data['students_completion']['more_than_80'] = 0
	data['students_completion']['completed_late'] = 0
	data['students_completion']['on_time'] = 0
	data['students_completion']['completed'] = 0
	if data['duration'] != 0
		if data['due_date'] > 0 # due date in future
			# data['students_completion']['not_watched'] = module_stats[0]
			data['students_completion']['incomplete'] = module_stats[0] + module_stats[1] 
			# data['students_completion']['less_than_50'] = module_stats[1]
			data['students_completion']['between_50_80'] = module_stats[2] 
			data['students_completion']['more_than_80'] = module_stats[3]
			data['students_completion']['completed'] = module_stats[4]
		else # due date is in past
			data['students_completion']['incomplete'] = module_stats[0] + module_stats[1] 
			data['students_completion']['between_50_80'] = module_stats[2] 
			data['students_completion']['more_than_80'] = module_stats[3]
			data['students_completion']['completed_late'] = module_stats[5]
			data['students_completion']['on_time'] = module_stats[4]
		end
	else
		data['duration'] = 1
	end
	return data
end

	def get_summary_teacher_for_each_online_quiz(online_quiz , students_count)
		data_online_quiz={}
		data_online_quiz[online_quiz.id]={}
		data_online_quiz[online_quiz.id]['lecture_name'] = online_quiz.lecture.name
		data_online_quiz[online_quiz.id]['quiz_name'] = online_quiz.question
		data_online_quiz[online_quiz.id]['data'] = {}
		grade_grouped_user_ids_list = {}
		online_quiz.online_quiz_grades.group_by{ |quiz_grade| quiz_grade.grade  }.each{|quiz_grade_group| grade_grouped_user_ids_list[quiz_grade_group[0]] =  quiz_grade_group[1].map{|e| e.user_id }.uniq  }
		online_quiz.free_online_quiz_grades.group_by{ |quiz_grade| quiz_grade.grade  }.each{|quiz_grade_group| grade_grouped_user_ids_list[quiz_grade_group[0]] =  quiz_grade_group[1].map{|e| e.user_id }.uniq  }

		if online_quiz.quiz_type.include?"survey"
			data_online_quiz[online_quiz.id]['type'] = 'survey'
			data_online_quiz[online_quiz.id]['data']['survey_solved'] = ( ( grade_grouped_user_ids_list[1.0] || [] ) + (grade_grouped_user_ids_list[0.0] || []) ).uniq.size
			data_online_quiz[online_quiz.id]['data']['never_tried'] = students_count - data_online_quiz[online_quiz.id]['data']['survey_solved']

			data_online_quiz[online_quiz.id]['answer'] = {}
			user_ids_attempt_online_answers  = online_quiz.online_quiz_grades.group(:user_id ).select('user_id as user_id , Max(attempt) as max').map{|a| [a.user_id ,  a.max.to_i ] }
			online_answers_list = online_quiz.online_quiz_grades.select{|a| user_ids_attempt_online_answers.include?([a.user_id , a.attempt.to_i]) }.map{|a| a.online_answer_id}
			online_quiz.online_answers.each do |online_answer|
					data_online_quiz[online_quiz.id]['answer'][online_answer.answer] = online_answers_list.count(online_answer.id)
			end
		else
			data_online_quiz[online_quiz.id]['type'] = 'quiz'
			data_online_quiz[online_quiz.id]['inclass'] = online_quiz.lecture.inclass
			data_online_quiz[online_quiz.id]['distance_peer'] = online_quiz.lecture.distance_peer

			if online_quiz.question_type != "Free Text Question"
				first_correct_attempt = online_quiz.online_quiz_grades.select{|q| q.attempt == 1 && q.grade == 1}.map(&:user_id).uniq
				first_correct_attempt += online_quiz.free_online_quiz_grades.select{|q| q.attempt == 1 && q.grade == 1}.map(&:user_id).uniq

				not_first_incorrect_attempt = online_quiz.online_quiz_grades.select{|q| q.attempt != 1 && q.grade == 0}.map(&:user_id).uniq
				not_first_incorrect_attempt += online_quiz.free_online_quiz_grades.select{|q| q.attempt != 1 && q.grade == 0}.map(&:user_id).uniq
				tried_not_correct = ( (grade_grouped_user_ids_list[0.0] || [] ) - (grade_grouped_user_ids_list[1.0] || []) - first_correct_attempt).uniq

				data_online_quiz[online_quiz.id]['data']['correct_first_try'] = first_correct_attempt.size
				data_online_quiz[online_quiz.id]['data']['tried_correct_finally'] = (  ( grade_grouped_user_ids_list[1.0] || []) - first_correct_attempt).uniq.size
				data_online_quiz[online_quiz.id]['data']['not_correct_first_try'] = ( (tried_not_correct || []) - (grade_grouped_user_ids_list[1.0] || []) - (first_correct_attempt || []) - (not_first_incorrect_attempt || []) ).uniq.size
				data_online_quiz[online_quiz.id]['data']['not_correct_many_tries'] = tried_not_correct.size - data_online_quiz[online_quiz.id]['data']['not_correct_first_try']
				data_online_quiz[online_quiz.id]['data']['never_tried'] = students_count - data_online_quiz[online_quiz.id]['data']['correct_first_try'] - data_online_quiz[online_quiz.id]['data']['tried_correct_finally'] -data_online_quiz[online_quiz.id]['data']['not_correct_many_tries'] -data_online_quiz[online_quiz.id]['data']['not_correct_first_try']
				data_online_quiz[online_quiz.id]['data']['review_vote'] = online_quiz.get_votes
				data_online_quiz[online_quiz.id]['data']['not_checked'] = 'null'
				data_online_quiz[online_quiz.id]['data']['correct_quiz'] = 'null'
				data_online_quiz[online_quiz.id]['data']['not_correct_quiz'] = 'null'
			else
				first_correct_attempt = online_quiz.online_quiz_grades.select{|q| q.attempt == 1 && q.grade == 3}.map(&:user_id).uniq
				first_correct_attempt += online_quiz.free_online_quiz_grades.select{|q| q.attempt == 1 && q.grade == 3}.map(&:user_id).uniq
				first_partial_correct_attempt = online_quiz.online_quiz_grades.select{|q| q.attempt == 1 && q.grade == 2}.map(&:user_id).uniq
				first_partial_correct_attempt += online_quiz.free_online_quiz_grades.select{|q| q.attempt == 1 && q.grade == 2}.map(&:user_id).uniq

				not_first_incorrect_attempt = online_quiz.online_quiz_grades.select{|q| q.attempt != 1 && q.grade == 1}.map(&:user_id).uniq
				not_first_incorrect_attempt += online_quiz.free_online_quiz_grades.select{|q| q.attempt != 1 && q.grade == 1}.map(&:user_id).uniq
				tried_not_correct = ( (grade_grouped_user_ids_list[1.0] || [] ) - (grade_grouped_user_ids_list[3.0] || []) - ( grade_grouped_user_ids_list[2.0] || [] )- first_partial_correct_attempt - first_correct_attempt).uniq

				data_online_quiz[online_quiz.id]['data']['correct_first_try'] = first_correct_attempt.size + first_partial_correct_attempt.size
				data_online_quiz[online_quiz.id]['data']['tried_correct_finally'] = (  ( grade_grouped_user_ids_list[3.0] || [] ) + ( grade_grouped_user_ids_list[2.0] || [] )- first_partial_correct_attempt - first_correct_attempt).uniq.size
				# data_online_quiz[online_quiz.id]['data']['tried_not_correct'] = ( (grade_grouped_user_ids_list[1.0] || [] ) - (grade_grouped_user_ids_list[3.0] || []) - ( grade_grouped_user_ids_list[2.0] || [] )- first_partial_correct_attempt - first_correct_attempt).uniq.size
				data_online_quiz[online_quiz.id]['data']['not_correct_first_try'] = ( (tried_not_correct || []) - (grade_grouped_user_ids_list[3.0] || []) - ( grade_grouped_user_ids_list[2.0] || [] )- first_partial_correct_attempt - first_correct_attempt -(not_first_incorrect_attempt || []) ).uniq.size
				data_online_quiz[online_quiz.id]['data']['not_correct_many_tries'] = tried_not_correct.size - data_online_quiz[online_quiz.id]['data']['not_correct_first_try']
				data_online_quiz[online_quiz.id]['data']['not_checked'] = ( (grade_grouped_user_ids_list[0.0] || [] ) - (grade_grouped_user_ids_list[3.0] || []) - ( grade_grouped_user_ids_list[2.0] || [] )- first_partial_correct_attempt - first_correct_attempt).uniq.size
				data_online_quiz[online_quiz.id]['data']['never_tried'] = students_count - data_online_quiz[online_quiz.id]['data']['correct_first_try'] - data_online_quiz[online_quiz.id]['data']['tried_correct_finally'] -data_online_quiz[online_quiz.id]['data']['not_correct_many_tries'] -data_online_quiz[online_quiz.id]['data']['not_correct_first_try'] - data_online_quiz[online_quiz.id]['data']['not_checked']
				data_online_quiz[online_quiz.id]['data']['review_vote'] = online_quiz.get_votes
				data_online_quiz[online_quiz.id]['data']['correct_quiz'] = 'null'
				data_online_quiz[online_quiz.id]['data']['not_correct_quiz'] = 'null'

			end
		end
		return data_online_quiz
	end

	def get_summary_teacher_for_each_normal_quiz(question , students_count)
		# "MCQ"    # "OCQ"    # "Free Text Question"    # "drag"
		data_question={}
		data_question[question.id]={}
		data_question[question.id]['lecture_name'] = question.quiz.name
		data_question[question.id]['quiz_name'] = question.content
		data_question[question.id]['data'] = {}
		grade_grouped_user_ids_list = {}


		question.quiz_grades.group_by{ |quiz_grade| quiz_grade.grade  }.each{|quiz_grade_group| grade_grouped_user_ids_list[quiz_grade_group[0]] =  quiz_grade_group[1].map{|e| e.user_id }.uniq  }
		question.free_answers.group_by{ |quiz_grade| quiz_grade.grade  }.each{|quiz_grade_group| grade_grouped_user_ids_list[quiz_grade_group[0]] =  quiz_grade_group[1].map{|e| e.user_id }.uniq  }
		if question.quiz.quiz_type == "survey"
			data_question[question.id]['type'] = 'survey'
			## added nil for survey quiz grades without grade 
			data_question[question.id]['data']['survey_solved'] = ( (grade_grouped_user_ids_list[1.0] || []) + (grade_grouped_user_ids_list[1] || []) + (grade_grouped_user_ids_list[0.0] || []) + (grade_grouped_user_ids_list[0] || []) + (grade_grouped_user_ids_list[nil] || [])).uniq.size
			data_question[question.id]['data']['never_tried'] = students_count - data_question[question.id]['data']['survey_solved']

			if question.question_type != "Free Text Question"
				data_question[question.id]['answer'] = {}
				answers_list = question.quiz_grades.map{|a| a.answer_id}
				question.answers.each do |answer|
						data_question[question.id]['answer'][answer.content] = answers_list.count(answer.id)
				end
			else
				data_question[question.id]['answer'] = {}
			end
		else
			data_question[question.id]['type'] = 'quiz'
			data_question[question.id]['inclass'] = false
			data_question[question.id]['distance_peer'] = false

			if question.question_type != "Free Text Question"

				data_question[question.id]['data']['correct_first_try'] = 'null'#( (grade_grouped_user_ids_list[1.0]||[]) + (grade_grouped_user_ids_list[1]||[]) ).uniq.size # first_correct_attempt.size
				data_question[question.id]['data']['correct_quiz'] =  ( (grade_grouped_user_ids_list[1.0]||[]) + (grade_grouped_user_ids_list[1]||[]) ).uniq.size#'null'
				data_question[question.id]['data']['tried_correct_finally'] = 'null' #(  ( grade_grouped_user_ids_list[1.0] || []) - first_correct_attempt).uniq.size
				data_question[question.id]['data']['not_correct_first_try'] = 'null'#( (grade_grouped_user_ids_list[0.0]||[]) + (grade_grouped_user_ids_list[0]||[]) - (grade_grouped_user_ids_list[1.0]||[]) - (grade_grouped_user_ids_list[1]||[]) ).uniq.size #( (tried_not_correct || []) - (grade_grouped_user_ids_list[1.0] || []) - (first_correct_attempt || []) - (not_first_incorrect_attempt || []) ).uniq.size
				data_question[question.id]['data']['not_correct_quiz'] =  ( (grade_grouped_user_ids_list[0.0]||[]) + (grade_grouped_user_ids_list[0]||[]) - (grade_grouped_user_ids_list[1.0]||[]) - (grade_grouped_user_ids_list[1]||[]) ).uniq.size#'null'
				data_question[question.id]['data']['not_correct_many_tries'] =  'null' #tried_not_correct.size - data_question[question.id]['data']['not_correct_first_try']
				data_question[question.id]['data']['never_tried'] = students_count - data_question[question.id]['data']['correct_quiz'] - data_question[question.id]['data']['not_correct_quiz']
				data_question[question.id]['data']['review_vote'] = 'null' #question.get_votes
				data_question[question.id]['data']['not_checked'] = 'null'
			else
				data_question[question.id]['data']['correct_first_try'] = 'null'#(  ( grade_grouped_user_ids_list[3] || [] ) + ( grade_grouped_user_ids_list[2] || [] )).uniq.size # first_correct_attempt.size + first_partial_correct_attempt.size
				data_question[question.id]['data']['correct_quiz'] =  (  ( grade_grouped_user_ids_list[3.0] || [] )+ ( grade_grouped_user_ids_list[3] || [] ) + ( grade_grouped_user_ids_list[2] || [] ) +  ( grade_grouped_user_ids_list[2.0] || [] )).uniq.size#'null'
				data_question[question.id]['data']['tried_correct_finally'] = 'null' #(  ( grade_grouped_user_ids_list[3.0] || [] ) + ( grade_grouped_user_ids_list[2.0] || [] )- first_partial_correct_attempt - first_correct_attempt).uniq.size
				data_question[question.id]['data']['not_correct_first_try'] = 'null'#( (grade_grouped_user_ids_list[1] || [] ) - (grade_grouped_user_ids_list[3] || []) - ( grade_grouped_user_ids_list[2] || [] )).uniq.size#( (tried_not_correct || []) - (grade_grouped_user_ids_list[3.0] || []) - ( grade_grouped_user_ids_list[2.0] || [] )- first_partial_correct_attempt - first_correct_attempt -(not_first_incorrect_attempt || []) ).uniq.size
				data_question[question.id]['data']['not_correct_quiz'] =  ( (grade_grouped_user_ids_list[1.0] || [] ) - (grade_grouped_user_ids_list[3.0] || []) - ( grade_grouped_user_ids_list[2.0] || [] )).uniq.size#'null'        
				data_question[question.id]['data']['not_correct_many_tries'] = 'null' #tried_not_correct.size - data_question[question.id]['data']['not_correct_first_try']
				data_question[question.id]['data']['not_checked'] = ( (grade_grouped_user_ids_list[0] || [] ) + (grade_grouped_user_ids_list[0.0] || [] ) - (grade_grouped_user_ids_list[3] || []) - (grade_grouped_user_ids_list[3.0] || []) - ( grade_grouped_user_ids_list[2] || [] ) - ( grade_grouped_user_ids_list[2.0] || [] )).uniq.size
				data_question[question.id]['data']['never_tried'] = students_count - data_question[question.id]['data']['correct_quiz'] - data_question[question.id]['data']['not_correct_quiz'] - data_question[question.id]['data']['not_checked']
				data_question[question.id]['data']['review_vote'] = 'null'#question.get_votes

			end
		end
		return data_question
	end

	def get_online_quiz_summary_teacher
		course = self.course
		students_count = course.users.size
		## Video Date
		online_quiz_data=[]
		data ={:online_quiz => []}

		self.get_items.each do |item|
			if item.class.name.downcase == 'lecture'
				# self.online_quizzes.includes([:online_answers,:lecture, :online_quiz_grades, :free_online_quiz_grades]).order('lectures.position , online_quizzes.start_time').each do |online_quiz|
				item.online_quizzes.includes([:online_answers,:lecture, :online_quiz_grades, :free_online_quiz_grades]).order('online_quizzes.start_time').each do |online_quiz|
						data_online_quiz = self.get_summary_teacher_for_each_online_quiz(online_quiz , students_count)  
						data[:online_quiz].push(data_online_quiz )
				end
			elsif item.class.name.downcase == 'quiz'
				item.questions.includes([:answers,:quiz, :quiz_grades, :free_answers]).order('questions.position').select{|q| q.question_type !='header'}.each do |question|
						data_normal_quiz = self.get_summary_teacher_for_each_normal_quiz(question , students_count)  
						data[:online_quiz].push(data_normal_quiz )
				end
			end
		end
		return data
	end


	def get_discussion_summary_teacher
		data = {}
		questions  = {}
		unanswered_posts = Forum::Post.get("get_questions_replies", {:group_id =>self.id })
		data['posts_total'] = unanswered_posts['posts_total']
		data['posts_answered'] = unanswered_posts['posts_answered']
		data['unanswered_questions_count'] = unanswered_posts['posts_total'] - unanswered_posts['posts_answered']

		unanswered_posts['posts'].each do |lecture|
			lecture_id = lecture[0].to_i
			questions[lecture_id] = {}
			questions[lecture_id]['name'] = Lecture.find(lecture_id).name
			questions[lecture_id]['lecture_id'] = lecture_id
			questions[lecture_id]['questions'] = {}
			lecture[1].group_by{|post| post['post_content']}.each do |post|
				post_content = post[0]
				questions[lecture_id]['questions'][post_content] = {}
				questions[lecture_id]['questions'][post_content]['content'] = post_content
				questions[lecture_id]['questions'][post_content]['privacy'] = post[1][0]['privacy']
				questions[lecture_id]['questions'][post_content]['time'] = post[1][0]['time']
				questions[lecture_id]['questions'][post_content]['group_id'] = post[1][0]['group_id']
				questions[lecture_id]['questions'][post_content]['lecture_id'] = post[1][0]['lecture_id']
				questions[lecture_id]['questions'][post_content]['id'] = post[1][0]['id']

				questions[lecture_id]['questions'][post_content]['comments_count'] = 0

				questions[lecture_id]['questions'][post_content]['comments'] = {}
				post[1].each_with_index do |comment,index|
					if comment['comment_content']
						questions[lecture_id]['questions'][post_content]['comments_count'] = 1
						questions[lecture_id]['questions'][post_content]['comments'][index] = {}
						questions[lecture_id]['questions'][post_content]['comments'][index]['name'] = User.find(comment['user_id']).screen_name
						questions[lecture_id]['questions'][post_content]['comments'][index]['content'] = comment['comment_content']
					end
				end
			end
		end
		data['unanswered_questions'] = questions
		return data
	end

	def get_module_summary_student(current_user)
		today = Time.now 
		course = self.course
		data = {}

		data['title'] = course.short_name+": "+self.name
		data['id'] = self.id
		data['course_id'] = course.id
		data['due_date'] = ((self.due_date.to_time - DateTime.current.to_time )) # get due date
		data['due_date_string'] = self.due_date
		data['type'] = "student"
		data['has_inclass'] = self.lectures.select{|a| a.inclass}.size > 0
		data['duration'] = self.lectures.select{|a| a.appearance_time <= today}.map(&:duration).select{|d| !d.nil?}.sum 
		data['quiz_count'] = self.quiz_count(true) + self.online_quiz_count(true) 
		data['survey_count'] = self.survey_count(true) +  self.online_survey_count(true) 
		all_views = self.lecture_views.where(:user_id => current_user.id).sort_by{|a| a.updated_at}
		if all_views.map(&:percent).size == 0
			data['module_done_perc'] = 0
		else
			data['module_done_perc'] = all_views.map(&:percent).sum /  ( self.lectures.size )
		end

		last_viewed = all_views.last    
		first_lecture = self.lectures.select{|lecture| lecture.appearance_time <= today }.first
		data['last_viewed'] = (!last_viewed.nil?)? last_viewed.lecture_id : -1
		data['first_lecture'] = (!first_lecture.nil?)? first_lecture.id : -1

		return data
  	end

	def get_completion_summary_student(current_user)
		today = Time.now 
		data = {}

		data['duration'] = self.lectures.select{|a| a.appearance_time <= today}.map(&:duration).select{|d| !d.nil?}.sum 
		data['quiz_count'] = self.quiz_count(true) + self.online_quiz_count(true) 
		data['survey_count'] = self.survey_count(true) +  self.online_survey_count(true) 

		data['module_done'] = current_user.finished_group_test?(self)

		data['total_finished_duration'] = 0
		data['module_percentage'] = 0

		lecture_views = current_user.lecture_views.select{|v| v.group_id==self.id }
		done_lectures_view = lecture_views.select{|v| v.percent==100}

		student_online_quiz_grades = current_user.online_quiz_grades.includes(:online_quiz).select{|v| v.group_id==self.id}
		done_online_quizzes = student_online_quiz_grades.uniq{|p| p.online_quiz_id}

		student_free_online_quiz_grades = current_user.free_online_quiz_grades.includes(:online_quiz).select{|v| v.group_id==self.id}
		done_free_online_quizzes = student_free_online_quiz_grades.uniq{|p| p.online_quiz_id}

		done_online_quiz_ids = []
		done_online_quiz_ids = ( done_online_quizzes.map { |e|  e.online_quiz_id } + done_free_online_quizzes.map { |e| e.online_quiz_id } ).uniq

		done_quiz_a = current_user.quiz_grades.includes(:quiz).select{|v| v.quiz.group_id==self.id}.uniq{|p| p.quiz_id}
		done_quiz_b = current_user.free_answers.includes(:quiz).select{|v| v.quiz.group_id==self.id}.uniq{|p| p.quiz_id}
		done_quiz_ids =[]
		done_quiz_ids = ( done_quiz_a.map { |e|  e.quiz_id } + done_quiz_b.map { |e| e.quiz_id } ).uniq

		data['finished_all_quiz_count'] =  0
		data['finished_all_survey_count'] =  0

		data['module_completion']=[]
		data['online_quiz_count']= self.online_quizzes.count + self.total_quiz_questions + self.total_survey_questions

		self.get_sub_items.each_with_index do |item , index|
			data_item = {}
			data_item['id'] = item.id
			data_item['group_id'] = item.group.id
			if item.appearance_time <= today 
				if item.class.name.downcase == 'lecture'
					lec_duration = item.duration || 0
					data_item['type'] = 'lecture'
					data['module_percentage'] += lec_duration
					lecture_view_percentage = lecture_views.select{|r| r.lecture_id == item.id}[0]
					data_item['duration'] = lec_duration
					data_item['percent_finished'] = 0
					data_item['item_name'] = item.name
					data_item['inclass'] = item.inclass
					data_item['distance_peer'] = item.distance_peer

					if lecture_view_percentage
						data_item['percent_finished'] = lecture_view_percentage.percent
						data['total_finished_duration'] +=  ( lecture_view_percentage.percent / 100.0 ) * lec_duration
					end
					d=done_online_quizzes.select{|r| r.lecture_id == item.id}
					e=done_free_online_quizzes.select{|r| r.lecture_id == item.id}
					g=done_lectures_view.select{|r| r.lecture_id == item.id}

					if (!(d.size+e.size < item.online_quizzes.size or g.empty?)) #means done.
							data_item['status'] = 'done'
					else
							data_item['status'] = 'not_done'
					end
					data_item['online_quizzes'] = []
					item.online_quizzes.order('start_time').each do |online_quiz|
						data_online_quiz={}
						data_online_quiz['lecture_id'] = online_quiz.lecture.id
						data_online_quiz['quiz_name'] = online_quiz.question
						data_online_quiz['id'] = online_quiz.id
						data_online_quiz['time'] = online_quiz.time
						data_online_quiz['required'] = online_quiz.graded 
						data_online_quiz['inclass'] = item.inclass
						data_online_quiz['distance_peer'] = item.distance_peer

						data_online_quiz['data'] = []

						if  online_quiz.quiz_type.include?"survey"
							data_online_quiz['type'] = 'survey'
							if done_online_quiz_ids.include?(online_quiz.id)
									data['finished_all_survey_count'] += 1
							end
							self_student_answers = student_online_quiz_grades.select{|grade| grade.online_quiz_id == online_quiz.id && !grade.inclass && !grade.distance_peer }
							group_student_answers = student_online_quiz_grades.select{|grade| grade.online_quiz_id == online_quiz.id && grade.inclass && grade.distance_peer }

							if  self_student_answers.size > 0
											data_online_quiz['data'].push('self_survey_solved')
							else
											data_online_quiz['data'].push('self_never_tried')
							end

							if item.inclass || item.distance_peer
								if group_student_answers
												data_online_quiz['data'].push('group_survey_solved')
								else
												data_online_quiz['data'].push('group_never_tried')
								end
							end
						else
							data_online_quiz['type'] = 'quiz'
							if done_online_quiz_ids.include?(online_quiz.id)
									data['finished_all_quiz_count'] += 1
							end
							self_student_answers = student_online_quiz_grades.select{|grade| grade.online_quiz_id == online_quiz.id && !grade.in_group }
							self_student_answers += student_free_online_quiz_grades.select{|grade| grade.online_quiz_id == online_quiz.id  }
							group_student_answers = student_online_quiz_grades.select{|grade| grade.online_quiz_id == online_quiz.id && grade.in_group }

							if online_quiz.question_type != "Free Text Question"
									if  self_student_answers.size > 0
										if self_student_answers.select{|grade| grade.attempt ==  1 && grade.grade ==  1}.size > 0
											data_online_quiz['data'].push('self_correct_first_try')
										elsif self_student_answers.select{|grade| grade.grade ==  1}.size  > 0
											data_online_quiz['data'].push('self_tried_correct_finally')
										elsif self_student_answers.select{|grade| grade.grade ==  0}.size  == 1
											data_online_quiz['data'].push('self_tried_not_correct_first')
										else
											data_online_quiz['data'].push('self_tried_not_correct_finally')
										end
									else
											data_online_quiz['data'].push('self_never_tried')
									end

									if item.inclass || item.distance_peer
										if group_student_answers.size >  0
											if group_student_answers.select{|grade| grade.attempt ==  1 && grade.grade ==  1}.size > 0
												data_online_quiz['data'].push('group_correct_first_try')
											elsif group_student_answers.select{|grade| grade.grade ==  1}.size  > 0
												data_online_quiz['data'].push('group_tried_correct_finally')
											elsif group_student_answers.select{|grade| grade.grade ==  0}.size  == 1
												data_online_quiz['data'].push('group_tried_not_correct_first')
											else
												data_online_quiz['data'].push('group_tried_not_correct_finally')
											end
										else
											data_online_quiz['data'].push('group_never_tried')
										end
									end
							else
								if  self_student_answers.size > 0
									if self_student_answers.select{|grade| grade.attempt ==  1 &&  ( grade.grade ==  3 || grade.grade ==  2 ) }.size > 0
										data_online_quiz['data'].push('self_correct_first_try')
									elsif self_student_answers.select{|grade| ( grade.grade ==  3 || grade.grade ==  2 ) }.size  > 0
										data_online_quiz['data'].push('self_tried_correct_finally')
									elsif self_student_answers.select{|grade|  grade.grade ==  0   }.size  > 0
										data_online_quiz['data'].push('self_not_checked')
									elsif self_student_answers.select{|grade|  grade.grade ==  1   }.size  == 1
										data_online_quiz['data'].push('self_tried_not_correct_first')
									else
										data_online_quiz['data'].push('self_tried_not_correct_finally')
									end
								else
									data_online_quiz['data'].push('self_never_tried')
								end
							end
						end
						data_item['online_quizzes'].push(data_online_quiz)
					end
					######  take care from it is required or not  ####################################################
			else ## QUIZ
					data_item['item_name'] = item.name
					## add 5 minutes
					data['module_percentage'] += 300
					data_item['duration'] = 300
					data_item['status'] = 'not_done'
					data_item['percent_finished'] = 0
					student_quiz_grades = current_user.quiz_grades.includes(:quiz).select{|v| v.quiz.group_id==self.id}
					quiz_student_free_online_quiz_grades = current_user.free_answers.includes(:quiz).select{|v| v.quiz.group_id==self.id}
					data_item['online_quizzes'] = []          

					if  item.quiz_type ==  "survey"
						data_item['type'] = 'survey'
						data_item['percent_finished'] = 0
						if done_quiz_ids.include?(item.id)
							data_item['status'] = 'done'
							data_item['percent_finished'] = 100
							data['finished_all_survey_count'] += 1
							data_item['finished_duration'] = 300
							data['remaining_duration'] = 0
						end
						item.questions.order('position').select{|q| q.question_type !='header'}.each do |question| 
							self_student_answers = student_quiz_grades.select{|grade| grade.question_id == question.id }
							self_student_answers += quiz_student_free_online_quiz_grades.select{|grade| grade.question_id == question.id }

							data_online_quiz={}
							data_online_quiz['lecture_id'] = question.quiz.id
							data_online_quiz['quiz_name'] = question.content
							data_online_quiz['id'] = question.id
							data_online_quiz['required'] = item.graded 
							data_online_quiz['inclass'] = false
							data_online_quiz['distance_peer'] = false
							data_online_quiz['data'] = []
							data_online_quiz['type'] = 'survey'
							if  self_student_answers.size > 0
								data_online_quiz['data'].push('self_survey_solved')
							else
								data_online_quiz['data'].push('self_never_tried')
							end
							data_item['online_quizzes'].push(data_online_quiz)
						end
					else
						data_item['type'] = 'quiz'
						if done_quiz_ids.include?(item.id)
							data_item['status'] = 'done'
							data_item['percent_finished'] = 100
							data['finished_all_quiz_count'] += 1
							data_item['finished_duration'] = 300
							data['remaining_duration'] = 0
						end
						item.questions.order('position').select{|q| q.question_type !='header'}.each do |question| 
							self_student_answers = student_quiz_grades.select{|grade| grade.question_id == question.id }
							self_student_answers += quiz_student_free_online_quiz_grades.select{|grade| grade.question_id == question.id }

							data_online_quiz={}
							data_online_quiz['lecture_id'] = question.quiz.id
							data_online_quiz['quiz_name'] = question.content
							data_online_quiz['id'] = question.id
							data_online_quiz['required'] = item.graded 
							data_online_quiz['inclass'] = false
							data_online_quiz['distance_peer'] = false
							data_online_quiz['data'] = []
							data_online_quiz['type'] = 'survey'

							if question.question_type != "Free Text Question"
								if  self_student_answers.size > 0
									# p self_student_answers
									if self_student_answers.select{|grade| grade.grade ==  1}.size > 0
										data_online_quiz['data'].push('self_correct_question')
									elsif self_student_answers.select{|grade| grade.grade ==  0}.size  > 0
										data_online_quiz['data'].push('self_not_correct_question')
									end
								else
										data_online_quiz['data'].push('self_never_tried')
								end
							else
								if  self_student_answers.size > 0
									if self_student_answers.select{|grade| ( grade.grade ==  3 || grade.grade ==  2 ) }.size > 0
										data_online_quiz['data'].push('self_correct_question')
									elsif self_student_answers.select{|grade|  grade.grade ==  0   }.size  > 0
										data_online_quiz['data'].push('self_not_checked_question')
									elsif self_student_answers.select{|grade|  grade.grade ==  1   }.size  > 0
										data_online_quiz['data'].push('self_not_correct_question')
									end
								else
									data_online_quiz['data'].push('self_never_tried')
								end
							end

							data_item['online_quizzes'].push(data_online_quiz)


						end
					end
				end
				data['module_completion'].push(data_item )
			end
		end

		if data['module_percentage'] == 0
				data['module_percentage'] = 1
		end 
		data['module_completion'].each{|g|  g['duration'] = ( g['duration'] /  data['module_percentage'] )*99 }
		data['remaining_duration'] = data['duration'] - data['total_finished_duration']
		data['remaining_quiz'] = data['quiz_count'] - data['finished_all_quiz_count']
		data['remaining_survey'] =  data['survey_count'] - data['finished_all_survey_count']

		return data
	end

	def get_discussion_summary_student(current_user)
		data = {}
		questions  = {}
		unanswered_posts = Forum::Post.get("get_questions_replies", {:group_id =>self.id , :user_id => current_user.id  })
		data['posts_total'] = unanswered_posts['posts_total']
		data['posts_answered'] = unanswered_posts['posts_answered']
		unanswered_posts['posts'].each do |lecture|
			lecture_id = lecture[0].to_i
			questions[lecture_id] = {}
			questions[lecture_id]['name'] = Lecture.find(lecture_id).name
			questions[lecture_id]['lecture_id'] = lecture_id
			questions[lecture_id]['questions'] = {}
			lecture[1].group_by{|post| post['post_content']}.each do |post|
				post_content = post[0]
				questions[lecture_id]['questions'][post_content] = {}
				questions[lecture_id]['questions'][post_content]['content'] = post_content
				questions[lecture_id]['questions'][post_content]['privacy'] = post[1][0]['privacy']
				questions[lecture_id]['questions'][post_content]['time'] = post[1][0]['time']
				questions[lecture_id]['questions'][post_content]['group_id'] = post[1][0]['group_id']
				questions[lecture_id]['questions'][post_content]['lecture_id'] = post[1][0]['lecture_id']
				questions[lecture_id]['questions'][post_content]['comments'] = {}
				post[1].each_with_index do |comment,index|
					if comment['comment_content']
						questions[lecture_id]['questions'][post_content]['comments'][index] = {}
						if User.exists?(comment['user_id']) 
							questions[lecture_id]['questions'][post_content]['comments'][index]['name'] = User.find(comment['user_id']).screen_name 
						else 
							questions[lecture_id]['questions'][post_content]['comments'][index]['name'] = I18n.t('groups.deleted_user') 
						end
						questions[lecture_id]['questions'][post_content]['comments'][index]['content'] = comment['comment_content']
					end
				end
			end
		end
		data['unanswered_questions'] = questions
		return data
	end

	private

		def appearance_date_must_be_before_items
			error=false
			lectures.each do |l|
				if l.appearance_time < appearance_time and l.appearance_time_module==false
					error=true
				end
			end
			errors.add(:appearance_time, I18n.t("group.errors.appearance_date_must_be_before_items") ) if error		
		end
		
		def due_date_must_be_after_items
			error=false
			(lectures+quizzes).each do |l|
				if l.due_date > due_date and l.due_date_module==false and l.due_date < (Time.now + 100.years)
					error=true
				end
			end
			errors.add(:due_date, I18n.t("group.errors.due_date_must_be_after_items") ) if error
		end

		def clean_up
			self.events.where(:lecture_id => nil, :quiz_id => nil).destroy_all			
		end
end