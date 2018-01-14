class NewsFeedController < ApplicationController
	
	def index
    	unfilterd_courses = []
      if current_user.is_administrator?
        unfilterd_courses = Course.all
      elsif current_user.is_school_administrator?
        email = current_user.email.split('@')[1]
        unfilterd_courses = Course.includes([:user,:teachers]).select{|c| c.teachers.map{|e| e.email.split("@")[1]}.include?(email) }
      else
      # elsif current_user.is_teacher?
        teacher_courses = current_user.subjects_to_teach
      # elsif current_user.is_student?
        student_courses = current_user.courses;
        unfilterd_courses = teacher_courses + student_courses
      end
      @courses = []

      latest_events = []
      latest_announcements = []

      unfilterd_courses.each do |course|
        if !course.ended
          # if current_user.is_student?
          #   lectures = Lecture.where("course_id = :course_id AND appearance_time <= :now ",{course_id: course.id, now: now}).includes(:course)
          #   quizzes = Quiz.where("course_id = :course_id AND appearance_time <= :now ",{course_id: course.id, now: now}).includes(:course)
          # end
          Time.zone = course.time_zone
          now = Time.zone.now
          announcements = course.announcements.where("updated_at <= :now",{now: now})

          announcements.each do |announcement|
            announcement[:course_name] = announcement.course.name
            # announcement[:class_name] = 'announcement'
            latest_announcements << announcement
          end
        end
      end
  		render json: {:latest_announcements => latest_announcements}
  	end
	
end