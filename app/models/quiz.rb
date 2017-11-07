class Quiz < ApplicationRecord 
  belongs_to :course, :touch => true
  belongs_to :group

  has_many :questions, -> { order :id }, :dependent => :destroy
  has_many :quiz_statuses, :dependent => :destroy
  has_many :assignment_item_statuses, :dependent => :destroy

  attribute :class_name
  attribute :current_user
  attribute :requirements

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
end
