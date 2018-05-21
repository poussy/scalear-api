# require "event_calendar"

class EventsController < ApplicationController
	before_action :correct_user
	before_action :get_course
	before_action :set_zone

	def correct_user
		# Checking to see if the current user is taking the course OR teaching the course, otherwise he is not authorised.
		@course=Course.find_by_id(params[:course_id])
		if !current_user && !(@course.users.include? current_user) && !(@course.guests.include? current_user) && !(@course.teachers.include? current_user) && !current_user.is_administrator? && !(@course.is_school_administrator(current_user))  #&& not administrator.
			render json: {:errors => [ t("controller_msg.you_are_not_authorized") ]}, status: 403
		end
	end


	def set_zone
		@course=Course.find(params[:course_id])
		Time.zone= @course.time_zone
	end

	def get_course
		@course=Course.find(params[:course_id])
	end

	def index
		@eventsAll= @course.events
		finalEvents = []
		@eventsAll.each do |event|
			if @course.correct_student(current_user)
				event_coloring = event.get_color(current_user)
				bg_color = event_coloring[:background]
				text_color = event_coloring[:text]
				status = event_coloring[:status]
				days = event_coloring[:days]
			else
				bg_color = "gray"
				text_color = "white"
				status = -1
				days = 0
			end
		finalEvents << {id: event.id,
			course_id: event.course_id,
			group_id:event.group_id,
			quiz_id:event.quiz_id,
			lecture_id:event.lecture_id,
			title: event.name,
			start: event.start_at,
			color: bg_color,
			textColor: text_color,
			course_short_name:event.course.short_name,
			course_name:event.course.name,
			status: status,
			days:days
		}
		end
		render json: {events: finalEvents }
	end
end