class VideoNote < ApplicationRecord
	belongs_to :user
	belongs_to :lecture

	serialize :data, JSON
end