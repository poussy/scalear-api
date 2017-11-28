class LecturesController < ApplicationController
	load_and_authorize_resource
		# @lecture is already loaded

	before_action :set_zone
	# # before_action :correct_user
	# # before_action :correct_id


	# # Removed to course model correct student && teacher
	# # def correct_user
	# # end

	# # def correct_id
	# # end

	def set_zone
		@course=Course.find(params[:course_id])
		Time.zone= @course.time_zone
	end

	# def index
	# end

	# def show
	# end

	# def new
	# end
	def update
		@lecture = Lecture.find(params[:id])
		@course= Course.find(params[:course_id])
		if params[:lecture][:due_date_module]==true 
			params[:lecture][:due_date]=@lecture.group.due_date
		end
		if params[:lecture][:appearance_time_module]== true 
			params[:lecture][:appearance_time]=@lecture.group.appearance_time
		end
		if params[:lecture][:required_module]== true 
			params[:lecture][:required]=@lecture.group.required
		end
		if params[:lecture][:graded_module]== true 
			params[:lecture][:graded]=@lecture.group.graded
		end
		did_he_change_lecture_type = @lecture.inclass != params[:lecture][:inclass]

		if @lecture.update_attributes(lecture_params)
			##### remove all onlinequiz.inclass_session and check added it if type isdistance peer
			@lecture.events.where(:quiz_id => nil, :group_id => @lecture.group.id).destroy_all
			if @lecture.due_date.to_formatted_s(:long) != @lecture.group.due_date.to_formatted_s(:long)
				@lecture.events << Event.new(:name => "#{@lecture.name} due", :start_at => params[:lecture][:due_date], :end_at => params[:lecture][:due_date], :all_day => false, :color => "red", :course_id => @course.id, :group_id => @lecture.group.id)
			end


			## update online_quiz.inclass  to be the same as lecture.inclass untill to remove online_quiz.inclass
			if did_he_change_lecture_type
				if @lecture.inclass
				# create inclass session
				@lecture.online_quizzes.each do |online_quiz|
					online_quiz.update_attributes(:hide => false)
					if online_quiz.inclass_session.nil?
					online_quiz.create_inclass_session(:status => 0, :lecture_id => online_quiz.lecture_id, :group_id => online_quiz.group_id, :course_id => online_quiz.course_id)
					end
				end
				else
				# delete inclass session
				@lecture.online_quizzes.each do |online_quiz|
					online_quiz.update_attributes(:hide => true)
					session = online_quiz.inclass_session
					if !session.nil?
					session.destroy
					end
				end
				end

			end
			@lecture.online_quizzes.each do |online_quiz|
				online_quiz.update_attributes(:inclass => @lecture.inclass)
			end

			render json: {lecture: @lecture, :notice => [I18n.t("controller_msg.lecture_successfully_updated")] }
		else
			render json: {:errors => @lecture.errors , :appearance_time =>@lecture.appearance_time.strftime('%Y-%m-%d')}, :status => :unprocessable_entity
		end

	end
	# def update_percent_view
	# end

	# def log_video_event
	# end

	# def save_html #when student answers an html online quiz
	# end

	# def save_online
	# end

	# def confused #can be atmost confused twice within 15 seconds. when once -> very false, when twice -> very true, if more will not save and alert you to ask a question instead.
	# end

	# def pause
	# end

	# def back
	# end

	# def confused_question
	# end

	def destroy
		@lecture = Lecture.find(params[:id])
		@course= params[:course_id]
		lec_destory = false
		ActiveRecord::Base.transaction do
			lec_destory = @lecture.destroy
		end
		if lec_destory
			## waitin for shared item table
			# SharedItem.delete_dependent("lecture",params[:id].to_i, current_user.id)
			# Post.delete("destroy_all_by_lecture", {:lecture_id => params[:id]})
			render json: {:notice => [I18n.t("controller_msg.lecture_successfully_deleted")]}
		else
			render json: {:errors => [I18n.t("lectures.could_not_delete_lecture")]}, :status => 400
		end
  	end

	def sort #called from module_editor to sort the lectures (by dragging)
		group = Group.find(params[:group])
		@lectures = group.lectures#.where(:group_id => params[:group])
		@quizzes = group.quizzes#.where(:group_id => params[:group])
		@links = group.custom_links#.where(:group_id => params[:group])
		params['items'].each_with_index do |it,index|
			if it['class_name'] == 'lecture'
				item = @lectures.find(it['id'])#(it['id'])
			elsif it['class_name'] == 'customlink'
				item = @links.find(it['id'])
			else
				item = @quizzes.find(it['id'])
			end
			item.position = index + 1
			item.save
		end

		render json: {:notice => [I18n.t("controller_msg.module_items_sorted")]}
  	end

	def new_lecture_angular #called from course_editor / module editor to add a new lecture
		group = Group.find(params[:group])
		items = group.get_items
		position = 1
		if !items.empty?
			position = items.last.position + 1
		end
		@lecture = @course.lectures.build(:name => "New Lecture", :appearance_time => group.appearance_time, 
			:due_date => group.due_date, :appearance_time_module => true, :due_date_module => true, 
			:required_module => true, :graded_module => true,:url => "none", :group_id => params[:group], 
			:slides => "none", :position => position, :start_time => 0, :end_time => 0, :inclass => params[:inclass] ,
			:distance_peer => params[:distance_peer] , :required=>group.required , :graded=>group.graded )
		@lecture['class_name']='lecture'
		if @lecture.save
			render json:{lecture: @lecture, :notice => [I18n.t("controller_msg.lecture_successfully_created")]}
		else
			render json: {:errors => @lecture.errors}, status: 400
		end
  	end

	# def get_lecture_angular
	# end

	# def get_quiz_list_angular
	# end

	def new_quiz_angular
		alert=""
		
		if params[:quiz_type] == 'survey' || params[:quiz_type] == "html_survey"
			title = "New Survey"
		else
			title = "New Quiz"
		end
		quiz = @lecture.online_quizzes.build(:group_id => @lecture.group_id, :course_id => params[:course_id], :question => title, 
				:time => params[:time], :start_time => params[:start_time], :end_time => params[:end_time], 
				:question_type => params[:ques_type], :quiz_type => params[:quiz_type], :inclass => params[:inclass])
		if quiz.save
			render json: {quiz: quiz, notice: "#{I18n.t('controller_msg.quiz_successfully_created')} - #{alert}", alert: alert}
		else
			render json: {errors:quiz.errors}, status: 400
		end
  	end

	def new_marker
		marker = @lecture.online_markers.build(:group_id => @lecture.group_id, :course_id => @lecture.course_id, :title => "", :annotation => "", :time => params[:time])
		if marker.save
			render json: {:marker => marker, notice: "#{I18n.t('controller_msg.marker_successfully_created')}"}
		else
			render json: {:errors => marker.errors}, status: 400
		end
	end

	def save_answers_angular
		OnlineQuiz.transaction do
			@online_quiz= OnlineQuiz.find(params[:online_quiz_id])
			old_answers=[]
			params[:answer].each do |k|
				if !k["id"].nil? #old one
					old_answers<<k["id"].to_i
					answer = OnlineAnswer.where(:id => k["id"].to_i).first
					if answer
						answer.update_attributes!(:explanation => k['explanation'], :answer => k['answer'], :correct => k['correct'] , :ycoor => k['ycoor'], :xcoor => k['xcoor'], :width => k['width'], :height => k['height'], :sub_ycoor => k['sub_ycoor'], :sub_xcoor => k['sub_xcoor'])
					end
				else  #new one
					y=@online_quiz.online_answers.create!(:pos => k['pos']||0, :explanation => k['explanation'], :answer => k['answer'], :correct => k['correct'] , :ycoor => k['ycoor'], :xcoor => k['xcoor'], :width => k['width'], :height => k['height'], :sub_ycoor => k['sub_ycoor'], :sub_xcoor => k['sub_xcoor'])
					old_answers<<y.id.to_i
				end
			end
			#delete old answers
			to_delete_a=@online_quiz.online_answers.pluck(:id)
			to_delete_a = to_delete_a - old_answers
			to_delete_a.each do |d|
				OnlineAnswer.find(d).destroy
			end
			if (@online_quiz.question_type=="Free Text Question" && @online_quiz.quiz_type=="html" && params[:match_type]=="Free Text") && @online_quiz.online_answers.count>0
				@online_quiz.online_answers.each do |ans|
					# ans.destroy
					ans.update_attributes!(:answer => '')
				end
			end
			render json: {:done => I18n.t('events.done'), :notice=>I18n.t("controller_msg.quiz_successfully_saved")} and return
		end
		render json: {:done => I18n.t('events.done'), :errors => [I18n.t("controller_msg.could_not_save_quiz")]}, :status => 400
  	end

	# def add_html_answer_angular #not used anymore
	# end

	# def remove_html_answer_angular #not used anymore
	# end

	# def get_position(oquiz, oanswers)
	# end

	# def add_answer_angular #creating an online answer, and associating it with an online quiz.
	# end

	# def remove_answer_angular  #remove online answer from an online_quiz
	# end

	def get_old_data_angular
		quiz= OnlineQuiz.find(params[:quiz])
		answers= quiz.online_answers
		num=[]
		num= answers.map{|n| n.pos} if !answers.empty?

		render json: {:answers => answers, :other_nums => num}
	end

	def get_html_data_angular
		quiz= OnlineQuiz.find(params[:quiz])
		answers= quiz.online_answers
		render json: {:answers => answers}
	end

	def get_lecture_data_angular
		@q= Lecture.where(:id => params[:id], :course_id => params[:course_id]).first
		if ((@q.nil? || @q.appearance_time > Time.zone.now.to_datetime) &&  !current_user.is_preview?) || @q.group.nil?
			render json: {errors: [t('controller_msg.no_such_lecture')]}, :status => 404 and return
		else
		item_pos= @q.id#group.lectures.index(@q)
		group_pos= @q.group_id #group.id#group.course.groups.index(group)
		next_i = @q.group.next_item(@q.position)
		next_item={}
		if !next_i.nil?
			next_item[:id] = next_i.id
			next_item[:class_name] = next_i.class.name.downcase
			next_item[:group_id]= next_i.group_id
		end
		today = Time.zone.now
		all = @q.group.lectures.select{|v| v.appearance_time <= today } +  @q.group.quizzes.select{ |v| v.appearance_time <= today}
		all.sort!{|x,y| ( x.position and y.position ) ? x.position <=> y.position : ( x.position ? -1 : 1 )  }
		requirements={:lecture=> [], :quiz => []}
		if @q.required
			all.each do |l|
				if l.id == @q.id
					break
				elsif l.required
					requirements[l.class.name.downcase.to_sym] << l.id
				end
			end
		end
		@q[:requirements] = requirements

		day2='day'.pluralize((Time.zone.now.to_date - @q.due_date.to_date).to_i)
		day= t("controller_msg.#{day2}")

		@alert_messages={}
		if @q.due_date < Time.zone.now
			@alert_messages['due']= [I18n.localize(@q.due_date, :format => '%d %b'), (Time.zone.now.to_date - @q.due_date.to_date).to_i, day2]
		elsif @q.due_date.to_date == Time.zone.today
			@alert_messages['today'] = @q.due_date#.strftime("%I:%M %p")
		end
		a=LectureView.where(:user_id => current_user.id, :course_id => params[:course_id], :lecture_id =>  params[:id])
		if a.empty?
			LectureView.create(:user_id => current_user.id, :group_id => @q.group_id, :course_id => params[:course_id], :lecture_id => params[:id], :percent => 0)
		else
			a = a.first
			a.updated_at = Time.now
			a.save
		end
		@q.current_user = current_user
			render :json => {:alert_messages => @alert_messages,:next_item => next_item, :lecture => @q, :done => [item_pos, group_pos, @q.is_done]}
		end
	end

	# def switch_quiz
	# end

	# def online_quizzes_solved
	# end

	
	def validate_lecture_angular
		if params[:lecture]
			params[:lecture].each do |key, value|
				@lecture[key]=value
			end
		end		
		if @lecture.valid?
			render json:{ :nothing => true }
		else
			render json: {errors:@lecture.errors.full_messages}, status: :unprocessable_entity
		end
	end


	# def create_or_update_survey_responses
	# end

	# def delete_response
	# end

	# # def get_progress_lecture
	# # end

	# def delete_confused
	# end

	# def save_note
	# end

	# def delete_note
	# end

	# def load_note
	# end

	def lecture_copy
		id = params[:id] || params[:lecture_id]
		old_lecture = Lecture.find(id)
		new_group = Group.find(params[:module_id])
		copy_lecture= old_lecture.dup
		copy_lecture.course_id = params[:course_id]
		copy_lecture.group_id  = params[:module_id]
		copy_lecture.position = new_group.get_items.size+1
		copy_lecture.appearance_time = new_group.appearance_time
		copy_lecture.due_date = new_group.due_date
		copy_lecture.appearance_time_module = true
		copy_lecture.due_date_module = true
		copy_lecture.required_module = true
		copy_lecture.graded_module = true


		copy_lecture.save(:validate => false)
		old_lecture.online_quizzes.each do |quiz|
			new_online_quiz = quiz.dup
			new_online_quiz.lecture_id= copy_lecture.id
			new_online_quiz.group_id  = copy_lecture.group_id
			new_online_quiz.course_id = copy_lecture.course_id
			new_online_quiz.save(:validate => false)
			quiz.online_answers.each do |answer|
				new_answer = answer.dup
				new_answer.online_quiz_id = new_online_quiz.id
				new_answer.save(:validate => false)
			end
			quiz_session = quiz.inclass_session
			if !quiz_session.nil?
				new_session = quiz_session.dup
				new_session.online_quiz_id= new_online_quiz.id
				new_session.lecture_id= copy_lecture.id
				new_session.group_id  = copy_lecture.group_id
				new_session.course_id = copy_lecture.course_id
				new_session.save(:validate => false)
			end
		end
		old_lecture.online_markers.each do |marker|
			new_online_marker = marker.dup
			new_online_marker.lecture_id= copy_lecture.id
			new_online_marker.group_id  = copy_lecture.group_id
			new_online_marker.course_id = copy_lecture.course_id
			new_online_marker.save(:validate => false)
		end
		Event.where(:quiz_id => nil,:lecture_id => old_lecture.id).each do |e|
			new_event= e.dup
			new_event.lecture_id = copy_lecture.id
			new_event.course_id = copy_lecture.course_id
			new_event.group_id = copy_lecture.group_id
			new_event.save(:validate => false)
		end

		render json:{lecture: copy_lecture, :notice => [I18n.t("controller_msg.lecture_successfully_updated")]}
  	end


	# def export_notes
	# end

	# def change_status_angular
	# end

	# def confused_show_inclass
	# end

	# def check_if_invited_distance_peer
	# end

	# def check_if_in_distance_peer_session
	# end

	# def invite_student_distance_peer
	# end

	# def check_invited_student_accepted_distance_peer
	# end

	# def accept_invation_distance_peer
	# end

	# def cancel_session_distance_peer
	# end

	# def change_status_distance_peer
	# end

	# def check_if_distance_peer_status_is_sync
	# end

	# def check_if_distance_peer_is_alive
	# end

	# # def end_distance_peer_session
	# # end

private
	def lecture_params
		params.require(:lecture).permit(:course_id, :description, :name, :url, :group_id, :appearance_time, :due_date, :duration,
			:aspect_ratio, :slides, :appearance_time_module, :due_date_module,:required_module , :inordered_module, 
			:position, :required, :inordered, :start_time, :end_time, :type, :graded, :graded_module, :inclass, :distance_peer, :parent_id )
	end
end