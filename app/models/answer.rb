class Answer < ApplicationRecord
	belongs_to :question
	has_many :quiz_grades, :dependent => :destroy

	serialize :content, Object
	serialize :explanation, Object

end