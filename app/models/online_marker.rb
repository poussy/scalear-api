class OnlineMarker < ApplicationRecord
	belongs_to :lecture, :touch => true
	belongs_to :group
	belongs_to :course

	validates :time, :lecture_id, :presence => true

end