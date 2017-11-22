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
	validates_inclusion_of :graded , :required, :in => [true, false] #not in presence because boolean false considered not present.

	@quiz_not_empty = Proc.new{|f| !f.online_answers.empty? or f.question_type=="Free Text Question"}
	
	validate :appearance_date_must_be_before_items
	validate :due_date_must_be_after_items
	validates_datetime :due_date, :on_or_after => lambda{|m| m.appearance_time}, :on_or_after_message => "group.errors.due_date_pass_after_appearance_date"

	attribute :total_time 
	attribute :items
	attribute :total_questions
	attribute :total_quiz_questions
	attribute :total_survey_questions
	attribute :total_lectures
	attribute :total_quizzes
	attribute :total_surveys
	attribute :total_links

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
			## waiting for discussion table
			# posts = Post.find(:all, :params => {lecture_id: lec.id})

			# posts.sort{|x,y| x.time <=> y.time}.each_with_index do |c, index|
			# 	discussion[[time,c.time, index]] = [c.time, c.content, lec.url]
			# end

			time+=(lec.duration || 0)
			time_list[time]=lec.url
			time_list2<<[lec.duration,lec.name]

		end
		return [confuseds,backs,pauses,discussion,time, time_list, time_list2, really_confuseds]
  	end


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
			self.events.where(:lecture_id => nil, :quiz_id => nil).destroy_all			
		end
end