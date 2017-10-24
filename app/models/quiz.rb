class Quiz < ApplicationRecord 
  belongs_to :course, :touch => true
  belongs_to :group
end
