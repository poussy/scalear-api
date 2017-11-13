class OnlineQuizzesController < ApplicationController
	# load_and_authorize_resource

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
		p params[:online_quiz]
		if online_quiz_params
			if online_quiz_params[:inclass]
				p "I got in?!"
				online_quiz_params[:hide]= false
				if @online_quiz.inclass_session.nil?
				@online_quiz.create_inclass_session(:status => 0, :lecture_id => @online_quiz.lecture_id, :group_id => @online_quiz.group_id, :course_id => @online_quiz.course_id)
				end
			elsif @online_quiz.inclass
				online_quiz_params[:hide]= true
				session = @online_quiz.inclass_session
				if !session.nil?
				session.destroy
				end
			end
		end
		p params
		p online_quiz_params
		if @online_quiz.update_attributes(online_quiz_params)
			@alert=""
				@quiz_times= @lecture.online_quizzes.where("id != ?", @online_quiz.id).pluck(:time)
				time=@online_quiz.time
				@quiz_times.each do |t|
					print "t is #{t}"
					print "time is #{time}"
					if (time-t<=5 and time-t>=0) or (t-time<=5 and t-time>=0) #another quiz within 5 seconds
						@alert = I18n.t('controller_msg.another_quiz_consider_shifting')
					end
				end

			render json: {notice: "#{I18n.t('controller_msg.quiz_successfully_updated')} - #{@alert}", alert: @alert}
		else
			render json: {errors: @online_quiz.errors}, status: :unprocessable_entity
		end
  	end
	
	# def destroy
	# end
	
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
	
	# def vote_for_review
	# end
	
	# def unvote_for_review
	# end
	
	# def hide_responses
	# end
	
	# def update_inclass_session
	# end
	
	# def get_chart_data
	# end
	
	# def get_inclass_session_votes
	# end
	
	# def update_grade
	# end
private

	def online_quiz_params
		params.require(:online_quiz).permit(:time ,:start_time ,:end_time ,:graded ,:intro ,
			:self ,:in_group ,:discussion ,:display_text, :inclass, :question)
	end
	
end