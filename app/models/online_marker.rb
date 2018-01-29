class OnlineMarker < ApplicationRecord
	belongs_to :lecture, :touch => true
	belongs_to :group
	belongs_to :course

	validates :time, :lecture_id, :course_id, :group_id, :xcoor, :ycoor, :presence => true

	validates :time, numericality: true

end