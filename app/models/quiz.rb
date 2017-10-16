class Quiz < ApplicationRecord 
  attr_accessible :course_id, :instructions, :name, :questions_attributes, :group_id, :due_date, :appearance_time,:appearance_time_module, :due_date_module, :required_module , :inordered_module,:position, :type, :visible, :required, :retries, :current_user, :inordered

  belongs_to :course, :touch => true
  belongs_to :group
end
