class FreeAnswer < ApplicationRecord
	belongs_to :quiz
	belongs_to :question
	belongs_to :user

	serialize :answer, Object
end