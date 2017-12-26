class User < ActiveRecord::Base

  include DeviseTokenAuth::Concerns::User
  

  before_create :add_default_user_role_to_user

  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :trackable, :validatable,
          :confirmable
          # :omniauthable

  attr_accessor :info_complete

  has_many :subjects, :class_name => "Course", :dependent => :destroy  # to get this call user.subjects

  has_many :enrollments, :dependent => :destroy
  has_many :courses, -> { distinct }, :through => :enrollments, :source => :course  # to get this call user.subjects


  has_many :teacher_enrollments, :dependent => :destroy
  has_many :subjects_to_teach, -> { distinct }, :through => :teacher_enrollments, :source => :course

  has_many :guest_enrollments, :dependent => :destroy
  has_many :guest_courses, -> { distinct }, :through => :guest_enrollments, :source => :course
  

  has_many :users_roles, :dependent => :destroy
  has_many :roles, -> { distinct }, :through => :users_roles

  # has_and_belongs_to_many :roles, -> {uniq} ,:join_table => :users_roles  
  has_many :shared_bys, :class_name => "SharedItem", :foreign_key => 'shared_by_id', :dependent => :destroy
  has_many :shared_withs, :class_name => "SharedItem", :foreign_key => 'shared_with_id', :dependent => :destroy

  has_many :announcements
  has_many :invitations, :dependent => :destroy
  has_many :quiz_statuses, :dependent => :destroy
  has_many :assignment_statuses, :dependent => :destroy
  has_many :assignment_item_statuses, :dependent => :destroy
  has_many :confuseds, :dependent => :destroy
  has_many :distance_peers, :dependent => :destroy
  has_many :free_answers, :dependent => :destroy
  has_many :free_online_quiz_grades, :dependent => :destroy
  has_many :lecture_views, :dependent => :destroy
  has_many :online_quiz_grades, :dependent => :destroy
  has_many :quiz_grades, :dependent=> :destroy#, :conditions => :user kda its like im defining a method called quiz grades, which returns something when user = ... not what i want.
  has_many :user_distance_peers, :dependent => :destroy
  has_many :video_events, :dependent => :destroy
  has_many :video_notes, :dependent => :destroy


  has_one :lti_key, :dependent => :destroy


  validates :name, :presence => true
  validates :last_name, :presence => true
  validates :screen_name, :presence => true, :uniqueness => true
  validates :university, :presence => true

  serialize :completion_wizard

  attribute :full_name
  attribute :status

  def has_role?(role)
    self.roles.pluck(:name).include?(role)      
  end

   # override devise function, to include methods with response
  def token_validation_response
    self.as_json(:methods => [:info_complete, :intro_watched])
  end
    
  def get_subdomains(email)
    subdomains = []
    subdomains = User.select(:email)
      .where("email like ? ", "%#{email}%")
      .map{|u| u.email.split('@')[1]}
      .uniq
      .select{|e| e != email }
    return subdomains
  end

  def is_school_administrator?
    role_ids.include?(9)
  end

  def info_complete
    return self.valid?
  end

  def intro_watched
    if self.completion_wizard
      return self.completion_wizard[:intro_watched]
    else
      return false
    end
  end

  def get_assignment_status(item)
    return self.assignment_statuses.select{|a| a.group_id == item.group_id}.first
  end
  
  def get_quiz_status(item)
    return self.assignment_item_statuses.select{|a| a.group_id == item.group_id && a.quiz_id == item.id && !a.lecture_id}.first
  end

  # def password_complexity
  # end

  # def self.teachers
  # end

  # def self.find_or_create_for_doorkeeper_oauth(oauth_data)
  # end

  # def update_doorkeeper_credentials(oauth_data)
  # end

  # def is_student?
  # end

  # def is_teacher?
  # end

  # def is_teacher_or_admin?
  # end

  # def is_prof?(course)
  # end

  # def is_ta?(course)
  # end

  # def is_administrator?
  # end

  def is_preview?
    role_ids.include?6
  end

  # def tutorials_taken
  # end

  # def add_admin_school_domain(domain)
  # end

  # def get_exact_stats(group)
  # end

  def get_online_quizzes_solved(lecture)
    return ((online_quiz_grades.includes(:online_quiz).select{|v| v.lecture_id == lecture.id &&  v.online_quiz.graded}.map{|t| t.online_quiz_id})+(free_online_quiz_grades.includes(:online_quiz).select{|v| v.lecture_id == lecture.id && v.online_quiz.graded}.map{|t| t.online_quiz_id})).sort.uniq
  end

  # def get_summary_table_online_quizzes_solved(lecture)
  # end

  
  def get_lecture_status(item)
    return self.assignment_item_statuses.select{|a| a.group_id == item.group_id && a.lecture_id == item.id && !a.quiz_id}.first

  end
  
  # def count_online_quizzes_solved(group)
  # end

  def get_lectures_viewed(lecture)
    return lecture_views.select{|v| v.lecture_id == lecture.id} #, :percent => 75
  end

  # def grades(course)          #
  # end

  # def quiz_grades2(group)           #
  # end

  # def group_quiz_grades(group)           #
  # end

  # def course_late_days(course)    #THIS HERE IS VERY SLOW!!!
  # end

  # def late_days(group)          #
  # end

  # def quiz_late_days(group)     #
  # end

  # def calculate_lectures_late_days(lectures)    #
  # end

  # def calculate_quizzes_late_days(quizzes)     #
  # end  

  # def calculate_late_days(lecture)
  # end

  # def calculate_quiz_late_days(quiz)
  # end

  # def finished_lecture_group?(lecture)
  # end

  # def finished_lecture_group_stats?(lecture)
  # end

  # def finished_quiz_group?(quiz)
  # end

  # def finished_group_boolean(group)
  # end

  # def finished_group?(group)
  # end  

  # def finished_group_stats?(group)
  # end

  # def finished_quizzes(quizzes)
  # end

  # def finished_surveys(surveys)
  # end

  # def finished_quiz(quiz)
  # end

  # def finished_survey(quiz) #done when just saved.
  # end

  # def finished_quizzes_on_time(quizzes)
  # end  

  # def finished_quiz_on_time(quiz)
  # end

  # def finished_lectures(lectures)  #if finished all online_quizzes AND opened the lecture
  # end

  # def finished_lectures_on_time(lectures)
  # end

  # def finished_lecture(lecture)
  # end

  # def finished_lecture_on_time(lecture)
  # end

  # def get_statistics(course, quiz_total, online_total)
  # end

  # def quizzes_percent(course, quiz_total)
  # end

  # def online_quizzes_percent(course, online_total) #old
  # end

  # def total_online_quiz(course)
  # end

  # def total_online_quiz_lecture(lecture)
  # end

  # def get_lecture_grade(lecture)
  # end

  # def total_online_quiz_quiz(quiz)
  # end

  # def total_quiz(course)
  # end

  # def get_quiz_grade(quiz)
  # end

  # def get_detailed_quiz_grade(quiz)  #
  # end

  # def get_detailed_lecture_grade(lecture)  #old
  # end  

  # def grades_angular_quiz_test(group)           #
  # end

  # def grades_angular_survey_test(group)           #
  # end

  # def grades_angular_lecture_test(group)
  # end

  def grades_angular_all_items(group)
    grades=[]
    ### id , day_finished , quiz solved , total quiz , optional quiz solved , optional total quiz , precentage, (1for lecture // 2for quiz)
    group.get_sub_items.each do |g|
      if g.class.name.downcase == 'lecture'
          views = LectureView.where(:user_id => self.id, :course_id => g.course_id, :lecture_id =>  g.id).first.percent rescue 0
          grades<<[g.id, self.finished_lecture_test?(g),views,1].flatten
      elsif g.class.name.downcase == 'quiz'
        if g.quiz_type == 'survey'
          # grades<<[g.id, self.finished_survey_test?(g),1,1,1,1,1,1]
          grades<<[g.id, self.finished_survey_test_with_completed_question_count?(g),2].flatten
        else
          # grades<<[g.id, self.finished_quiz_test?(g),0,0,0,0,0,0]
          ### id , day_finished , quiz solved , total quiz , optional quiz solved , 0, 0, (1for lecture // 2for quiz)
          grades<<[g.id, self.finished_quiz_test_with_correct_question_count?(g),2].flatten
        end
      end
    end
    return grades
  end

  # def finished_quiz_test?(quiz)
  # end

  def finished_quiz_test_with_correct_question_count?(quiz)
    inst=self.quiz_statuses.select{|v| v.quiz_id==quiz.id and v.status=="Submitted"}[0]
    day_finished = 0
    total_question_count = quiz.questions.where("question_type !=?", 'header').count
    ocq_mcq_grade = self.quiz_grades.includes(:question,:quiz).where(quiz_id: quiz.id).uniq{|q| q.question_id}.group_by{|a| a.grade} #0.0 ,1.0
    drag_grades = self.free_answers.includes(:question,:quiz).select{|answer| answer.quiz_id ==quiz.id && answer.question.question_type == 'drag'}.uniq{|q| q.question_id}.group_by{|a| a.grade} #0
    free_text_grades = self.free_answers.includes(:question,:quiz).select{|answer| answer.quiz_id ==quiz.id && answer.question.question_type != 'drag'}.uniq{|q| q.question_id}.group_by{|a| a.grade} #1
    correct_answers_question = (ocq_mcq_grade[1.0] || []).count +  (drag_grades[1] || []).count + (free_text_grades[2] || []).count + (free_text_grades[3] || []).count
    not_checked_question = (free_text_grades[0] || []).count

    if inst.nil?
      day_finished = -1
    elsif inst.created_at < quiz.due_date
      day_finished = 0
    else
      day_finished = (inst.created_at.to_date - quiz.due_date.to_date).to_i  #solved after lecture due date
    end
    ### day_finished , quiz solved , total quiz , optional quiz solved , 0 , (1for lecture // 2for quiz)
    return [ day_finished , correct_answers_question, total_question_count ,not_checked_question, 0 ,0 ]
  end

  # def finished_survey_test?(survey)
  # end

  def finished_survey_test_with_completed_question_count?(survey)
    total_question_count = survey.questions.where("question_type !=?", 'header').count
    ocq_mcq_grade = self.quiz_grades.includes(:question,:quiz).where(quiz_id: survey.id).uniq{|q| q.question_id}
    free_text_grades = self.free_answers.includes(:question,:quiz).select{|answer| answer.quiz_id ==survey.id && !answer.answer.nil? }.uniq{|q| q.question_id}
    completed_count = (ocq_mcq_grade || []).count +  (free_text_grades || []).count
    day_finished = 0
    inst=self.quiz_statuses.select{|v| v.quiz_id==survey.id and v.status=="Saved"}[0]
    if inst.nil?
      day_finished = -1
    elsif inst.created_at < survey.due_date
      day_finished = 0
    else
      day_finished = (inst.created_at.to_date - survey.due_date.to_date).to_i  #solved after lecture due date
    end
    ### day_finished , quiz solved , total quiz , 0 , 0 , (1for lecture // 2for quiz)
    return [ day_finished , completed_count, total_question_count ,0, 0 ,0 ]
  end

  def finished_lecture_test?(lecture)
      viewed=self.lecture_views.select{|v| v.lecture_id == lecture.id && v.percent == 100}[0]
      max=a1=a2=c=0
      all_online_quiz = lecture.online_quizzes.includes(:online_answers).select{|f| (!f.online_answers.empty? || f.question_type=="Free Text Question" )}.group_by {|n| n.graded? ? :graded : :not_graded}
      all_online_quiz_grades = lecture.online_quiz_grades.includes(:online_quiz).select{|v|  v.user_id==self.id && v.attempt == 1}.uniq{|v| v.online_quiz_id}.group_by {|n| n.online_quiz.graded? ? :graded : :not_graded}
      all_free_online_quiz_grades = lecture.free_online_quiz_grades.includes(:online_quiz).select{|v| v.user_id==self.id && v.attempt == 1}.uniq{|v| v.online_quiz_id}.group_by {|n| n.online_quiz.graded? ? :graded : :not_graded}

      total= all_online_quiz[:graded] || []
      a=all_online_quiz_grades[:graded] || []
      b=all_free_online_quiz_grades[:graded] || []

      total_optional= all_online_quiz[:not_graded] || []
      a_optional=all_online_quiz_grades[:not_graded] || []
      b_optional=all_free_online_quiz_grades[:not_graded] || []

      if a.size + b.size < total.size or viewed.nil?
        return [-1, a.size+b.size, total.size,a_optional.size+b_optional.size, total_optional.size]
      else
        a1=a.max_by{|obj| obj.created_at }.created_at.to_date - lecture.due_date.to_date if !a.empty?
        a2=b.max_by{|obj| obj.created_at }.created_at.to_date - lecture.due_date.to_date if !b.empty?
        c=viewed.created_at.to_date - lecture.due_date.to_date
      end

    return [ [max,a1,a2,c].max.to_i, a.size+b.size, total.size, a_optional.size+b_optional.size, total_optional.size]
  end

  def get_finished_lecture_quizzes_count(lecture)
      total= lecture.online_quizzes.select{|f| f.graded && (!f.online_answers.empty? or f.question_type=="Free Text Question")}.count
      a=lecture.online_quiz_grades.includes(:online_quiz).select{|v| v.user_id==self.id && v.online_quiz.graded }.uniq{|v| v.online_quiz_id}.count
      b=lecture.free_online_quiz_grades.includes(:online_quiz).select{|v| v.user_id==self.id && v.online_quiz.graded}.uniq{|v| v.online_quiz_id}.count
      return [a+b, total]
  end


  def grades_angular_test(item)
    grades=[]
    item.groups.each do |g|
      grades<<[g.id, self.finished_group_test?(g),0,0]
    end
    return grades    
  end

  def group_grades_test(course)
    grades={}
    course.groups.each do |g|
      grades[g.id] = self.finished_group_test?(g)
    end
    return grades
  end

  def finished_group_test?(group)
    lec_prog= finished_lectures_test(group)
    quiz_prog= finished_quizzes_test(group)


    if lec_prog==-1 || quiz_prog==-1
      return -1
    else
      if lec_prog>quiz_prog
        return lec_prog
      else
        return quiz_prog
      end
    end    
  end

  def finished_quizzes_test(group)
    status = {}
    self.assignment_item_statuses.select{|a| a.group_id == group.id && !a.lecture_id}.each do |s|
      status[s.quiz_id] = s.status
    end

    max=0
    a=self.quiz_statuses.select{|v|
      v.group_id == group.id &&
      v.quiz.graded &&
      (status[v.quiz_id].nil? || status[v.quiz_id] !=1) &&
      ((v.quiz.quiz_type=="quiz" && v.status.downcase=="submitted") ||
      (v.quiz.quiz_type=="survey" && v.status.downcase=="saved" ))
    }

    b= group.quizzes.select{|v|
      v.graded &&
      (status[v.id].nil? || status[v.id] !=1)
    }

    if a.size!=b.size
      return -1
    else
      a.each do |m|
        new_max= m.created_at.to_date - m.quiz.due_date.to_date
        max= new_max if new_max>max
      end
      return max.to_i
    end    
  end

  # def finished_lectures_test_percent(group) #called per student
  # end

  def finished_group_percent(group) #called per student
    group_online_quizzes= group.online_quizzes.select{|f| !f.online_answers.empty? or f.question_type=="Free Text Question"}
    online_quizzes_count = group_online_quizzes.size

    a = group.online_quiz_grades.select{|v| v.user_id == self.id}.uniq{|p| p.online_quiz_id}
    b = group.free_online_quiz_grades.select{|v| v.user_id==self.id}.uniq{|p| p.online_quiz_id}
    c = group.lecture_views.select{|v| v.user_id==self.id and v.percent==100}

    quiz_a = group.quizzes.flat_map{|q| q.quiz_grades}.select{|q| q.user_id == self.id}.uniq{|p| p.quiz_id}
    quiz_b = group.quizzes.flat_map{|q| q.free_answers}.select{|q| q.user_id == self.id}.uniq{|p| p.quiz_id}
    solved_quiz_ids_count = ( quiz_a.map{|e| e.quiz_id } + quiz_b.map{|e| e.quiz_id } ).uniq.size
    lecture_count = group.lectures.size
    quiz_count = group.quizzes.size

    if ( ((lecture_count != 0 && c.size == 0) && (quiz_count !=0 && (solved_quiz_ids_count == 0))) || ((lecture_count == 0 ) && (quiz_count != 0 && (solved_quiz_ids_count == 0))) || ((lecture_count !=0 && c.size == 0) && (quiz_count == 0)) )
      return 0 # not started
    elsif (lecture_count == c.size && online_quizzes_count == a.size+b.size && quiz_count == solved_quiz_ids_count)
      (a+b+c).each do |m|
        if m.created_at > m.lecture.due_date
          return 3 #late
        end
      end
      (quiz_a + quiz_b).each do |m|
        if m.created_at > m.quiz.due_date
          return 3 #late
        end
      end
    else
      num=0
      group.lectures.each do |l|
        d=a.select{|q| q.lecture_id == l.id}
        e=b.select{|q| q.lecture_id == l.id}
        g=c.select{|v| v.lecture_id == l.id}
        lec_quiz_count = group_online_quizzes.select{|q| q.lecture_id == l.id }.size
        if (!(d.size+e.size < lec_quiz_count || g.empty?)) #means done.
          num+=1
        end
      end
      num += solved_quiz_ids_count
      percent =  num * 1.0 / (quiz_count + lecture_count)
      (0.5..0.8).include?(percent)
      if (0.5..0.8).include?(percent)
        return 1 #  80% > finished > 50%
      elsif (0..0.5).include?(percent)
        return 4 # finished < 50%
      else
        return 5 #   finished > 80%
      end
    end
    return 2 #ontime
  end

  # def grades_module_before_due_date(group)
  # end

  def finished_lectures_test(group)
    status = {}
    self.assignment_item_statuses.select{|a| a.group_id == group.id && !a.quiz_id}.each do |s|
      status[s.lecture_id] = s.status
    end

    max=0
    a=self.online_quiz_grades.select{|v|
      v.group_id == group.id &&
      v.lecture.graded &&
      v.online_quiz.graded &&
      (status[v.lecture_id].nil? || status[v.lecture_id] !=1) &&
      v.attempt == 1
    }.uniq{|p| p.online_quiz_id}
    b=self.free_online_quiz_grades.select{|v|
      v.group_id == group.id &&
      v.lecture.graded &&
      v.online_quiz.graded &&
      (status[v.lecture_id].nil? || status[v.lecture_id] !=1) &&
      v.attempt == 1
      }.uniq{|p| p.online_quiz_id}
    c=self.lecture_views.select{|v|
      v.group_id == group.id &&
      v.lecture.graded &&
      v.percent == 100 &&
      (status[v.lecture_id].nil? || status[v.lecture_id] !=1)
    }
    if !(
      group.lectures.select{|l|
        l.graded &&
        (status[l.id].nil? || status[l.id] !=1)
      }.size == c.size &&
      group.online_quizzes.select{|q|
        q.graded &&
        q.lecture.graded &&
        (!q.online_answers.empty? || q.question_type=="Free Text Question") &&
        (status[q.lecture_id].nil? || status[q.lecture_id] !=1)
      }.size== a.size+b.size) #solved all    //.select{|q| q.lecture.graded == true}
      return -1 #-1 means not finished
    else
      # 0 means finished on time, any other n, means finished late with n as the late days

      a.each do |m|
        new_max= m.created_at.to_date - m.lecture.due_date.to_date
        max= new_max if new_max>max
      end
      b.each do |m|
        new_max= m.created_at.to_date - m.lecture.due_date.to_date
        max= new_max if new_max>max
      end
      c.each do |m|
        new_max= m.created_at.to_date - m.lecture.due_date.to_date
        max= new_max if new_max>max
      end
    end
    return max.to_i    
  end

  # def grades_angular(item)          #
  # end      

  # def self.delete_demo_users(course) #change according to course.
  # end

  # def self.students
  # end

  def remove_student(course_id)   #should i add them as associations (belong to/ has_many) ?
    if enrollments.where(:course_id => course_id).destroy_all
      return true
    else
      return false
    end
  end

  # def self.search(search)
  # end

  def full_name
    if !self.last_name.nil?
      return self.name + ' ' + self.last_name
    else
      return self.name
    end    
  end

  # def full_name_reverse
  # end

  # def reset_password!(new_password, new_password_confirmation)
  # end

  # def async_destroy
  # end

  def delete_student_data(course_id)
    ActiveRecord::Base.transaction do
      Confused.where(:user_id => id, :course_id => course_id).destroy_all
      LectureView.where(:user_id => id, :course_id => course_id).destroy_all
      QuizStatus.where(:user_id => id, :course_id => course_id).destroy_all
      VideoEvent.where(:user_id => id, :course_id => course_id).destroy_all
      course=Course.find(course_id)
      course.quizzes.each do |quiz|
        QuizGrade.where(:user_id => id, :quiz_id => quiz.id).destroy_all
        FreeAnswer.where(:user_id => id, :quiz_id => quiz.id).destroy_all
      end
      course.lectures.each do |lecture|
        VideoNote.where(:user_id => id, :lecture_id => lecture.id).destroy_all
        OnlineQuizGrade.where(:user_id => id, :lecture_id => lecture.id).destroy_all
        FreeOnlineQuizGrade.where(:user_id => id, :lecture_id => lecture.id).destroy_all
        Forum::Post.delete('destroy_all_by_user', {:user_id => id, :lecture_id => lecture.id} )
      end
    end
  end  

  private
      def add_default_user_role_to_user
        if !self.has_role?('User') 
          self.users_roles.build(role_id:1)
        end
        return true
      end

end