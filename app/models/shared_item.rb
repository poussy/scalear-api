class SharedItem < ApplicationRecord
	belongs_to :shared_by, :class_name => 'User', :foreign_key => "shared_by_id"
	belongs_to :shared_with, :class_name => 'User', :foreign_key => "shared_with_id"

	validates_presence_of :shared_by_id, :shared_with_id, :data

	serialize :data, JSON

	def sharer_email
		shared_by.email
	end

	def name
		"Data shared by #{sharer_email}"
	end

	def has_data?
		self.data.each do |key, value|
			if value && value.size > 0
				return true
			end
		end
		return false
	end

	def self.delete_dependent(type, id, user_id)
		SharedItem.where(:shared_by_id => user_id).each do |s|
			data = s.data["#{type}"]
			if data && data.size > 0 && ( data.include?(id) )
				data.delete id
				if s.has_data?
					s.save
				else
					s.destroy
				end
			end
		end
	end

end
