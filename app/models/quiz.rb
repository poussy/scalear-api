class Quiz < ApplicationRecord 
  belongs_to :course, :touch => true
  belongs_to :group

  has_many :questions, -> { order :id }, :dependent => :destroy
  has_many :quiz_statuses, :dependent => :destroy
  has_many :assignment_item_statuses, :dependent => :destroy
  has_many :events
  has_many :free_answers, :dependent => :destroy
  has_many :quiz_grades , :dependent => :destroy

  attribute :class_name
  attribute :current_user
  attribute :requirements

  validates :retries, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0 }
  validates :name, :appearance_time,:due_date,:course_id, :group_id, :presence => true
  validates_inclusion_of :appearance_time_module, :due_date_module,:required_module , :graded_module, :in => [true, false]

  validates_datetime :appearance_time, :on_or_after => lambda{|m| m.group.appearance_time}, :on_or_after_message => "must be after module appearance time"
  validate :due_before_module_due_date

  after_destroy :clean_up

  def is_done
    st=current_user
    assign= st.get_assignment_status(self)
    assign_quiz = st.get_quiz_status(self)
    if (!assign.nil? && assign.status==1) || (!assign_quiz.nil? && assign_quiz.status==1)#modified status and marked as done on time
      return true
    elsif quiz_type == 'quiz'
      return st.quiz_statuses.select{|v| v.quiz_id == id and v.status == "Submitted"}.size!=0
    else
      return st.quiz_statuses.select{|v| v.quiz_id == id and v.status == "Saved"}.size!=0
    end
  end

  def due_before_module_due_date
    error=false
    if self.due_date && self.due_date > self.group.due_date && self.due_date < (Time.now + 100.years)
       error=true
    end
    errors.add(:due_date, "must be before module due date") if error
  end

  # def get_class_name
  # end

  # def has_not_appeared
  # end

  # def present_quiz_type
  # end

  # def is_done_summary_table
  # end

  # def is_done_user(st)
  # end

  # def is_done?(user_asking)
  # end

  # def get_checked_survey_questions
  # end

  # def get_survey_data(students_id)
  # end

  # def get_survey_display_data(students_id)
  # end

  # def get_survey_categories
  # end

  # def get_survey_display_categories
  # end

  # def get_survey_free_text
  # end

  # def get_survey_display_free_text
  # end

  # def get_numbering
  # end

  # def get_display_numbering
  # end

  # def get_survey_data_angular(students_id)
  # end

  # def get_quiz_display_data_angular(students_id)
  # end

  # def get_quiz_free_text_angular
  # end

  # def get_survey_free_text_angular
  # end

  # def get_quiz_display_free_text_angular
  # end

  # def get_survey_student_display_free_text_angular
  # end

  # def get_survey_student_display_data_angular(students_id)
  # end

  private
    def clean_up
      self.events.where(:lecture_id => nil).destroy_all
    end
end    
