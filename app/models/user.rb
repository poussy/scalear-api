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

  # def grades_angular_all_items(group)
  # end

  # def finished_quiz_test?(quiz)
  # end

  # def finished_quiz_test_with_correct_question_count?(quiz)
  # end

  # def finished_survey_test?(survey)
  # end

  # def finished_survey_test_with_completed_question_count?(survey)
  # end

  # def finished_lecture_test?(lecture)
  # end

  # def get_finished_lecture_quizzes_count(lecture)
  # end

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

  # def finished_group_percent(group) #called per student
  # end

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