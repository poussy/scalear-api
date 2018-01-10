class DashboardController < ApplicationController
	# skip_before_filter :check_user_signed_in?, :only => [:dynamic_url ]
	
	def get_dashboard
		user = User.where(:id => current_user.id).includes({:online_quiz_grades => [:online_quiz, :lecture]}, {:free_online_quiz_grades => [:online_quiz , :lecture] }, {:lecture_views => :lecture }, :assignment_item_statuses, {:quiz_statuses => :quiz})[0]
		teacher_events = []
		student_events = []
		if user.is_administrator?
			teacher_courses = Course.pluck(:id)
			student_courses = []
			module_teacher_courses = user.subjects_to_teach.pluck("courses.id")
		elsif current_user.is_school_administrator?
			email = current_user.email.split('@')[1]
			teacher_courses = Course.includes([:user,:teachers]).all.select{|c| c.teachers.map{|e| e.email.split("@")[1]}.include?(email) }.map { |e| e.id }
			student_courses = []
			module_teacher_courses = user.subjects_to_teach.pluck("courses.id")
		else
			teacher_courses = user.subjects_to_teach.pluck("courses.id")
			student_courses = user.courses.pluck("courses.id")
			module_teacher_courses = teacher_courses
		end

		today = Time.now
		filter = lambda{|ev|
			(ev.start_at < today+100.years) &&
			(!ev.lecture_id && !ev.quiz_id && ev.group.appearance_time <= today) ||
			(ev.lecture_id && ev.lecture.appearance_time <= today) ||
			(ev.quiz_id && ev.quiz.appearance_time <= today)
		}

		teacher_events = Event.where(:course_id => teacher_courses).includes([:course, :group, :lecture, :quiz]).select(&filter) if teacher_courses.size > 0
		student_events = Event.where(:course_id => student_courses).includes([:course, {:group => [:lectures, {:online_quizzes => [:lecture, :online_answers]}, :quizzes]}, {:lecture =>[:online_quizzes, :online_quiz_grades, :free_online_quiz_grades]}, :quiz]).select(&filter) if student_courses.size > 0

		module_summary_id_list = []
		if (student_courses+ module_teacher_courses).size > 0
			module_events = Event.where(:course_id => module_teacher_courses + student_courses, :quiz_id => nil ,:lecture_id => nil).order(:start_at)
			due_items = module_events.where(:start_at => DateTime.current..(DateTime.current + 1.week))
			if(due_items.size == 0)
				due_items = module_events.where("start_at between ? and ?",DateTime.current+ 1.week, DateTime.current + 100.years).limit(1)
			end
			if due_items.size > 0
				due_items.each do |d|
					if d.group.appearance_time  <= today 
						module_summary_id_list.push([ d.group_id,d.course_id, module_teacher_courses.include?(d.course_id)? "teacher": "student"])
					end
				end
			end
		end

		final_events = []

		teacher_events.each do |event|
			final_events << {
				id: event.id,
				course_id: event.course_id,
				group_id:event.group_id,
				quiz_id:event.quiz_id,
				lecture_id:event.lecture_id,
				title: event.name,
				start: event.start_at,
				color: "gray",
				textColor: "white",
				course_short_name:event.course.short_name,
				course_name:event.course.name,
				status: -1,
				days:0,
				role: 1
			}
		end

		student_events.each do |event|
			event_coloring = event.get_color(user)
			final_events << {
				id: event.id,
				course_id: event.course_id,
				group_id:event.group_id,
				quiz_id:event.quiz_id,
				lecture_id:event.lecture_id,
				title: event.name,
				start: event.start_at,
				color: event_coloring[:background],
				textColor: event_coloring[:text],
				course_short_name:event.course.short_name,
				course_name:event.course.name,
				status: event_coloring[:status],
				days:event_coloring[:days],
				role: 2
			}
		end

		key = AESCrypt.encrypt(user.id, ENV["user_ase_key"])

		render json: {events: final_events, key:key , module_summary_id_list:module_summary_id_list}
	end

	def dynamic_url
			key = params[:key].tr(" ","+")
			id =  AESCrypt.decrypt(key,ENV["user_ase_key"])
			puts id
			current_user = User.find(id)
			puts current_user
			user = User.where(:id => current_user.id).includes({:online_quiz_grades => [:online_quiz, :lecture]}, {:free_online_quiz_grades => [:online_quiz , :lecture] }, {:lecture_views => :lecture }, :assignment_item_statuses, {:quiz_statuses => :quiz})[0]
			teacher_events = []
			student_events = []
			today = Time.now 
			if user.is_administrator?
					teacher_courses = Course.where("end_date > ?", today).pluck(:id) 
					student_courses = []
			elsif current_user.is_school_administrator?
					email = current_user.email.split('@')[1]
					 teacher_courses = Course.includes([:user,:teachers]).where("end_date > ?", today).select{|c| c.teachers.map{|e| e.email.split("@")[1]}.include?(email) }.map { |e| e.id } 
					student_courses = []
			else
				teacher_courses = user.subjects_to_teach.where("end_date > ?", today).pluck("courses.id") 
      			student_courses = user.courses.where("end_date > ?", today).pluck("courses.id") 
			end

			filter = lambda{|ev|
					(ev.start_at < today+100.years) &&
					(!ev.lecture_id && !ev.quiz_id && ev.group.appearance_time <= today) ||
					(ev.lecture_id && ev.lecture.appearance_time <= today) ||
					(ev.quiz_id && ev.quiz.appearance_time <= today)
			}

			events_all = []
			events_all << Event.where(:course_id => teacher_courses).includes([:course, :group, :lecture, :quiz]).select(&filter) if teacher_courses.size > 0
			events_all << Event.where(:course_id => student_courses).includes([:course, {:group => [:lectures, {:online_quizzes => [:lecture, :online_answers]}, :quizzes]}, {:lecture =>[:online_quizzes, :online_quiz_grades, :free_online_quiz_grades]}, :quiz]).select(&filter) if student_courses.size > 0

			time_zone = 'Etc/UTC'
			if TZInfo::Timezone.all_identifiers.include?((params[:tz]))
					time_zone = params[:tz]
			end

			calendar_event = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\n"
			calendar_event += "BEGIN:VTIMEZONE\r\n"
			calendar_event += "TZID:"+time_zone+"\r\n"
			calendar_event += "END:VTIMEZONE\r\n"
			events_all.each do |course_events|
					course_events.each do |event|
							start_at_time_zone = event.start_at.in_time_zone(time_zone)
							calendar_event += "BEGIN:VEVENT\r\nCLASS:PUBLIC\r\n"
							calendar_event += "DESCRIPTION:"+event.course.short_name+": "+event.name.split(" due")[0]+" "+I18n.t("controller_msg.due").capitalize+" "+I18n.t("at")+" "+start_at_time_zone.strftime("%H:%M")+" "+root_url.split("en")[0]+"#/courses/"+event.course_id.to_s+"\r\n" #/modules/2308/progress\r\n"
							calendar_event += "DTSTART:"+start_at_time_zone.strftime("%Y%m%d")+"T"+start_at_time_zone.strftime("%H%M%S")+"\r\n"
							calendar_event += "DTEND:"+start_at_time_zone.strftime("%Y%m%d")+"T"+start_at_time_zone.strftime("%H%M%S")+"\r\n"
							calendar_event += "LOCATION:Scalable-Learning\r\n"
							calendar_event += "SUMMARY;LANGUAGE=en-us:"+event.course.short_name+": "+event.name.split(" due")[0]+"\r\n"
							calendar_event += "TRANSP:TRANSPARENT\r\n"
							calendar_event += "END:VEVENT\r\n"
					end
			end
			calendar_event += "END:VCALENDAR"
			render :json => calendar_event.strip
	end

end