class AssignmentStatus < ApplicationRecord
    
    belongs_to :course
    belongs_to :group
    belongs_to :user
    
    validates :status, :inclusion => { :in => [1, 2] } #1 for ontime #2 for late #no record for original.
    validates_uniqueness_of :user_id,  :scope => :group_id #the pair group_id user_id must be unique
    
end
