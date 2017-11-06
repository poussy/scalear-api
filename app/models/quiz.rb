class Quiz < ApplicationRecord 
  belongs_to :course, :touch => true
  belongs_to :group

  has_many :questions, -> { order :id }, :dependent => :destroy

  attribute :class_name
end
