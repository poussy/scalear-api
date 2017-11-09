class UserDistancePeer < ApplicationRecord
	belongs_to :distance_peer
	belongs_to :user
	belongs_to :online_quiz

	validates :distance_peer_id, :online_quiz_id, :user_id, :status, :presence => true
end