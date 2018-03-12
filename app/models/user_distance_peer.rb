class UserDistancePeer < ApplicationRecord
	belongs_to :distance_peer
	belongs_to :user
	belongs_to :online_quiz, optional: true

	validates :distance_peer_id, :user_id, :status, :presence => true
end