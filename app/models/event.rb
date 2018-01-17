class Event < ApplicationRecord
	# has_event_calendar
	belongs_to :quiz, optional: true
	belongs_to :course
	belongs_to :group, optional: true
	belongs_to :lecture, optional: true


	validates :course_id, :name, :presence => true #can't have group_id because it is added after saving the group! so validation fails.

	# after_validation :message

	# def message
	# end

	# def self.appeared?(course)
	# end

	def get_color(current_user)
		Time.zone = self.course.time_zone
		color=""
		text =""
		green  = {:bg => "#d6edd1", :text => "#648161" }
		red    = {:bg => "#ecb8bf", :text => "#9c4d59" }
		orange = {:bg => "#fccab1", :text => "#d26717" }
		blue   = {:bg => "#d1ddf0", :text => "#546d8e" }
		status = -1
		days = 0

		if lecture_id.nil? and quiz_id.nil? #module event
				assignment_statuses = current_user.assignment_statuses.find_by_group_id(self.group.id) 
				if current_user.assignment_statuses.find_by_group_id(self.group.id)
						if assignment_statuses.status == 1
								days = 0 
						elsif assignment_statuses.status == 2
								days = -1
						end
				else 
						days = current_user.finished_group_test?(self.group)
				end
		elsif !quiz_id.nil? #quiz event
				q= self.quiz
				if !q.is_done_user(current_user)
						if q.quiz_type=='quiz'
								days = current_user.finished_quiz_test?(q)
						elsif q.quiz_type=='survey'
								days = current_user.finished_survey_test?(q)
						end
				end
		elsif !lecture_id.nil?
				l = self.lecture
				if !l.is_done_user(current_user)
						days = current_user.finished_lecture_test?(l)[0]
				end
		end
		if days > 0 #Done late
				days = days
				color= orange[:bg]
				text = orange[:text]
				status = 2
		elsif days == 0 #Done on time
				color= green[:bg]
				text = green[:text]
				status = 1
		elsif days < 0 #Not Done
				if (start_at - Time.zone.now) < 0 #late
						color= red[:bg]
						text = red[:text]
						status = 3
				else #still have time
						color= blue[:bg]
						text = blue[:text]
						status = 0
				end
		end
		return {:background => color, :text => text, :status => status, :days => days}
	end
end