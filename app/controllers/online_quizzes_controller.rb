class OnlineQuizzesController < ApplicationController
	load_and_authorize_resource

	def validate_name
		@online_quiz= OnlineQuiz.find(params[:id])
		params[:online_quiz].each do |key, value|
			@online_quiz[key]=value
		end
	
		if @online_quiz.valid?
			head :ok
		else
			render json: {errors: @online_quiz.errors.full_messages}, status: :unprocessable_entity
		end
		
  	end
	
	def update
		@online_quiz = OnlineQuiz.find(params[:id])
		@lecture= @online_quiz.lecture
		
		if online_quiz_params
			if online_quiz_params[:inclass]
				@online_quiz[:hide] = false
				if @online_quiz.inclass_session.nil?
					@online_quiz.create_inclass_session(:status => 0, :lecture_id => @online_quiz.lecture_id, :group_id => @online_quiz.group_id, :course_id => @online_quiz.course_id)
				end
			elsif @online_quiz.inclass ## in case online_quiz_params[:inclass] == false
				@online_quiz[:hide] = true
				session = @online_quiz.inclass_session
				if !session.nil?
					session.destroy
				end
			end
		end
		
		if @online_quiz.update_attributes(online_quiz_params)
			
			@alert=""
			@quiz_times= @lecture.online_quizzes.where("id != ?", @online_quiz.id).pluck(:time)
			time=@online_quiz.time
			@quiz_times.each do |t|
				if (time-t<=5 and time-t>=0) or (t-time<=5 and t-time>=0) #another quiz within 5 seconds
					@alert = I18n.t('controller_msg.another_quiz_consider_shifting')
				end
			end

			render json: {notice: "#{I18n.t('controller_msg.quiz_successfully_updated')} - #{@alert}", alert: @alert}
		else
			render json: {errors: @online_quiz.errors}, status: :unprocessable_entity
		end
  	end
  
	def destroy
		@online_quiz.destroy
		
		render json: {:notice => [I18n.t("controller_msg.quiz_successfully_deleted")]}
	end
	
	def get_quiz_list_angular
		lecture = Lecture.find(params[:lecture_id])
		quizList = lecture.online_quizzes.includes(:inclass_session)
		quizList.each do |quiz|
			if quiz.question_type == "Free Text Question"
				if quiz.online_answers.size > 0 && !quiz.online_answers.first.answer.blank?
					quiz[:match_type] = "Match Text"
				else
					quiz[:match_type] = "Free Text"
				end
			end
			if quiz.inclass
				quiz[:inclass_session] = quiz.inclass_session
			end
		end
		render json: {:quizList => quizList, :status=>"success"}
  	end

	def vote_for_review
		quiz = OnlineQuiz.find(params[:id])
		if quiz.question_type.upcase=="FREE TEXT QUESTION" || (quiz.quiz_type.upcase =="HTML" && quiz.question_type.upcase=="DRAG")
			quiz_grades= quiz.free_online_quiz_grades.where(:user_id => current_user.id, :attempt => 1)
		else
			quiz_grades= quiz.online_quiz_grades.where(:user_id => current_user.id, :attempt => 1)

		end
		quiz_grades.each do |quiz_grade|
			if !quiz_grade.nil?
				quiz_grade.review_vote = true
				quiz_grade.save
			end
		end
		render :json => {:done => true}
	end

	def unvote_for_review
		quiz = OnlineQuiz.find(params[:id])
		if quiz.question_type.upcase=="FREE TEXT QUESTION" || (quiz.quiz_type.upcase =="HTML" && quiz.question_type.upcase=="DRAG")
			quiz_grades= quiz.free_online_quiz_grades.where(:user_id => current_user.id, :attempt => 1)
		else
			quiz_grades= quiz.online_quiz_grades.where(:user_id => current_user.id, :attempt => 1)
		end
		quiz_grades.each do |quiz_grade|
			if !quiz_grade.nil?
				quiz_grade.review_vote = false
				quiz_grade.save
			end
		end
		render :json => {:done => true}
	end
	def hide_responses
		if params[:hide]["hide"]
			hidden=I18n.t("hidden")
		else
			hidden=I18n.t("visible")
		end

		if FreeOnlineQuizGrade.find(params[:hide]["id"]).update_attributes(:hide => params[:hide]["hide"])
			render :json => {:notice => ["#{I18n.t('controller_msg.response_is_now')} #{hidden}"]}
		else
			render :json => {:errors => [I18n.t("quizzes.could_not_update_response")]}, :status => 400
		end
	end
	
	def update_inclass_session
		quiz = OnlineQuiz.find(params[:id])
		session = quiz.inclass_session
		if !session.nil?
			if session.update_attributes(:status => params[:status])
				render :json => {:notice => [I18n.t("quizzes.updated")]}
			else
				render :json => {:errors => [I18n.t("quizzes.could_not_update")]}, :status => 400
			end
		else
			render :json => {:errors => [I18n.t("quizzes.could_not_update")]}, :status => 400
		end

	end
	
	def get_chart_data
		students_ids = @online_quiz.course.users.map(&:id)
		render json: {:chart => @online_quiz.get_chart(students_ids) }
	end
	
	def get_inclass_session_votes
		votes = OnlineQuizGrade.where(:online_quiz_id => params[:id], :in_group => params[:in_group] == "true", :attempt => 1).select("count(distinct user_id) as c")[0].c rescue 0 #needs to make sure its ok from karim
		lecture_ids = Lecture.find(params[:lecture_id]).group.lectures.where(:inclass => true).pluck(:id)
		max_votes = OnlineQuizGrade.where(:lecture_id => lecture_ids, :attempt => 1).select("count(distinct user_id) as c").group(:online_quiz_id, :in_group).order("c desc").limit(1).first["c"] rescue 0
		render json: {votes: votes, max_votes: max_votes}
	end
	
	def update_grade
		if @online_quiz.free_online_quiz_grades.find(params[:answer_id]).update_attributes(:grade => params[:grade])
			render :json => {:notice => I18n.t("controller_msg.grade_updated")}
		else
			render :json => {:errors => [I18n.t("controller_msg.grade_update_fail")]}, :status => 400
		end
	end
private

	def online_quiz_params
		params.require(:online_quiz).permit(:time ,:start_time ,:end_time ,:graded ,:intro ,
			:self ,:in_group ,:discussion ,:display_text, :inclass, :question)
	end
	
end