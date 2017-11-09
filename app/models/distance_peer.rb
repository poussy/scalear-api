class DistancePeer < ApplicationRecord
	belongs_to :user
	belongs_to :lecture
	belongs_to :course
	belongs_to :group

	has_many :user_distance_peers, :dependent => :destroy
end