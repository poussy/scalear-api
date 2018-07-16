class Quiz < ApplicationRecord 
  belongs_to :course, :touch => true
  belongs_to :group

  has_many :questions, -> { order :id }, :dependent => :destroy
  has_many :quiz_statuses, :dependent => :destroy
  has_many :assignment_item_statuses, :dependent => :destroy
  has_many :events, :dependent => :destroy
  has_many :free_answers, :dependent => :destroy
  has_many :quiz_grades , :dependent => :destroy

  attribute :class_name
  attribute :current_user
  attribute :requirements
  attribute :done
  attribute :questions_count

  after_initialize do
    self[:questions_count] = self.questions.count
  end

  before_update do
    self[:show_explanation] = true if !self[:exam]
  end

  validates :retries, :correct_question_count, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0 }
  validates :name, :appearance_time,:due_date,:course_id, :group_id, :presence => true
  validates_inclusion_of :appearance_time_module, :due_date_module,:required_module , :graded_module, :in => [true, false]

  validates_datetime :appearance_time, :on_or_after => lambda{|m| m.group.appearance_time}, :on_or_after_message => "must be after module appearance time"
  validate :due_before_module_due_date

  after_destroy :clean_up

  def remove_null_virtual_attributes
    quiz = self.as_json({})
    ["class_name","current_user","requirements","done"].each{|attr| quiz.delete(attr) unless quiz[attr]}
    quiz
  end

  def is_done
    assign= current_user.get_assignment_status(self)
    assign_quiz = current_user.get_quiz_status(self)
    if (!assign.nil? && assign.status==1) || (!assign_quiz.nil? && assign_quiz.status==1)
      return true
    elsif quiz_type == 'quiz'
      return current_user.quiz_statuses.where(:quiz_id => id, :status =>"Submitted").count !=0
    else
      return current_user.quiz_statuses.where(:quiz_id => id, :status =>"Saved").count !=0
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

  def is_done_user(st)
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

  def get_numbering
    @data={}
    count=1
    questions.select{|v| v.question_type == 'Free Text Question'}.each do |question|
      question.free_answers.select{|v| v.answer != ''}.each do |ans|
        if @data[ans.user_id].nil?
          @data[ans.user_id]=count
          count+=1
        end
      end
    end
    return @data
  end

  # def get_display_numbering
  # end

  def get_survey_data_angular(students_id)
    data={}
    questions.select{|v| v.question_type != 'Free Text Question'and v.question_type != 'header'}.each do |question|
      answers={}
      question.answers.each do |answer|
        answers[answer.id] = [answer.quiz_grades.select{|grade| students_id.include?(grade.user_id)}.size, answer.content]
      end
      data[question.id]={}
      data[question.id][:show] = question.show
      data[question.id][:student_show] = question.student_show
      data[question.id][:answers] = answers
      data[question.id][:title] = question.content
    end
    return data
  end

  def get_quiz_display_data_angular(students_id)
    data={}
    questions.select{|v| v.question_type != 'Free Text Question' and v.question_type != 'header' and v.show==true}.each do |question|
      answers={}
      question.answers.each do |answer|
        if question.question_type != "drag"
          answers[answer.id] = [answer.quiz_grades.select{|grade| students_id.include?(grade.user_id)}.size, "grey", answer.content]
          answers[answer.id][1] = "green" if self.quiz_type == 'quiz' && answer.correct
        else
          correct_answer=answer.content
          question.free_answers.each do |grade|
            correct_answer.each_with_index do |text,index|
              answers[text]=[0,"green","#{text} in correct place"] if answers[text].nil?
              answers[text][0] += 1 if grade.answer[index] == text
            end
          end
        end
      end
      data[question.id]={}
      data[question.id][:show] = question.show
      data[question.id][:student_show] = question.student_show
      data[question.id][:answers] = answers
      data[question.id][:title] = question.content
    end
    return data
  end

  # def get_quiz_free_text_angular
  # end

  def get_survey_free_text_angular
    @data={}
    questions.select{|v| v.question_type == 'Free Text Question'}.each do |question|
      @data[question.id]= question.free_answers.select{|v| v.answer != ''}
    end
    return @data
  end

  def get_quiz_display_free_text_angular
    @data={}
      questions.select{|v| v.question_type == 'Free Text Question' and v.show==true}.each do |question|
        @data[question.id]= question.free_answers.select{|v| v.answer != '' and v.hide==false}
    end
    return @data
  end

  def get_survey_student_display_free_text_angular
    @data={}
    questions.select{|v| v.question_type == 'Free Text Question' and v.student_show==true}.each do |question|
      @data[question.id]= question.free_answers.select{|v| v.answer != '' and v.student_hide==false}
    end
    return @data
  end

  def get_survey_student_display_data_angular(students_id)
    data={}
    questions.select{|v| v.question_type != 'Free Text Question' and v.question_type != 'header' and v.student_show==true}.each do |question|
      answers={}
      question.answers.each do |answer|
        answers[answer.id] = [answer.quiz_grades.select{|grade| students_id.include?(grade.user_id)}.size, answer.content]
      end
      data[question.id]={}
      data[question.id][:show] = question.show
      data[question.id][:student_show] = question.student_show
      data[question.id][:answers] = answers
      data[question.id][:title] = question.content
    end
    return data
  end

  private
    def clean_up
      self.events.where(:lecture_id => nil).destroy_all
    end
end    
