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
		if params[:lecture][:skip_ahead_module]== true 
			params[:lecture][:skip_ahead]=@lecture.group.skip_ahead 
		end 

		did_he_change_lecture_type = @lecture.inclass != params[:lecture][:inclass]
	  puts "lecture params ==========>"
		puts lecture_params
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

			render json: {lecture: @lecture.remove_null_virtual_attributes, :notice => [I18n.t("controller_msg.lecture_successfully_updated")] }
		else
			render json: {:errors => @lecture.errors , :appearance_time =>@lecture.appearance_time.strftime('%Y-%m-%d')}, :status => :unprocessable_entity
		end

	end
	def get_uploading_status
		current_upload = VimeoUpload.find_by_lecture_id(params["id"].to_i)
		@progress = current_upload.status if current_upload
		puts "------------------------------------------------------"
		puts "---------------------get_uploading_status---------------------------------"
		puts @progress
		puts "------------------------------------------------------"
		if current_upload==nil
			render json:{status: 	"none", :notice => ["lectures.no_video_upload"]}
	  elsif 	@progress
			render json:{status: 	@progress, :notice => ["lectures.video_is_transcoding"]}
		else
			render json: {:errors => "error"}, status: 400
		end
	end	

	def update_vimeo_table
		if params["status"] == "complete" && params["status"]
			@new_vimeo_upload=VimeoUpload.find_by_vimeo_url(params["url"])
			@new_vimeo_upload.status="complete"
			@lecture.update(name:params["title"]) if @lecture.name == "New Lecture"
		else
			@new_vimeo_upload = VimeoUpload.new(:vimeo_url=>params["url"],:user_id=>current_user.id,:status=>'transcoding',:lecture_id=>params["id"])
		end

		if @new_vimeo_upload.save
			render json:{new_vimeo_upload: @new_vimeo_upload, :notice => ["lectures.video_successfully_uploaded"]}
		else
			render json: {:errors => @new_vimeo_upload.errors}, status: 400
		end
	end	
	def get_vimeo_video_id
		current_upload = VimeoUpload.find_by_lecture_id(params["id"].to_i)
		@vimeo_video_id = current_upload.vimeo_url.split('https://vimeo.com/')[1] if current_upload
		puts "------------------------------------------------------"
		puts "---------------------get_vimeo_video_id---------------------------------"
		puts @vimeo_video_id
		puts "------------------------------------------------------"
		if current_upload==nil
			render json:{ vimeo_video_id: 	"none", :notice => ["lectures.no_video_upload"]}
	  elsif 	@vimeo_video_id
			render json:{ vimeo_video_id: 	@vimeo_video_id, :notice => ["lectures.vimeo_video_id_is_returned"]}
		else
			render json:{ :errors => "error"}, status: 400
		end
	end
  def update_percent_view
    lecture = Lecture.find(params[:id])
    end_offset_percent = ( (lecture.duration - 5) * 100 ) / lecture.duration rescue 0
    lecture.current_user=current_user
    views = LectureView.where(:user_id => current_user.id, :course_id => params[:course_id], :lecture_id =>  params[:id])
    percent = params[:percent]
    if percent.nil? || percent < 0
      percent = 0
    elsif percent >= end_offset_percent
      percent = 100
    end

    if views.empty?
      view = LectureView.new(:user_id => current_user.id, :group_id => lecture.group_id, :course_id => lecture.course_id, :lecture_id => lecture.id, :percent => 0)
    else
      view = views.first
    end

    obj = { :watched => view.percent, :quizzes_done => current_user.get_finished_lecture_quizzes_count(lecture)}
    if percent > view.percent
      view.percent = percent
      if view.save
        obj[:notice] = [I18n.t("controller_msg.lecture_successfully_updated")]
        obj[:watched] = view.percent
        obj[:lecture_done] = lecture.is_done
        render json: obj
      else
        render json: {:errors => view.errors}, :status => :unprocessable_entity
      end
    else
      obj[:lecture_done] = lecture.is_done
      render json: obj
    end
  end

  def log_video_event
    @lecture= Lecture.find(params[:id])
    event_type = VideoEvent.get_event params[:event]
    VideoEvent.create(:event_type => event_type, :lecture_id => @lecture.id, :group_id => @lecture.group_id, :course_id => @lecture.course_id, :user_id => current_user.id, :from_time => params[:from_time], :to_time => params[:to_time], :in_quiz => params[:in_quiz], :speed => params[:speed], :volume => params[:volume], :fullscreen => params[:fullscreen])
    render json: {}
  end

  def save_html #when student answers an html online quiz
    @answer= params[:answer]
    @quiz= params[:quiz]
    @lecture= Lecture.find(params[:id])
    #@grade = params[:correct]=="Correct" ? 1 : 0
    online_quiz = OnlineQuiz.find(@quiz)
    answered_inclass = params[:inclass] || false
    answered_in_group = params[:in_group] || false
    answered_distance_peer = params[:distance_peer] || false
    group=@lecture.group
    item_pos=params[:id]#group.lectures.index(@lecture)
    group_pos= group.id #course.groups.index(group)
    @lecture.current_user=current_user

    if online_quiz.inclass && answered_inclass
      views = LectureView.where(:user_id => current_user.id,  :lecture_id =>  params[:id])
      if views.empty?
        LectureView.create(:user_id => current_user.id, :group_id =>  @lecture.group_id, :course_id =>  @lecture.course_id, :lecture_id =>  params[:id], :percent => 100)
      elsif views.first && views.first.percent < 100
        views.first.update_attribute(:percent, 100)
      end
    end

    if(online_quiz.question_type=="MCQ") #MCQ

      quiz_grades = OnlineQuizGrade.where(:user_id => current_user.id, :online_quiz_id => @quiz, :in_group => answered_in_group )
      attempt = quiz_grades.sort{|x,y| x.attempt <=> y.attempt }.last.attempt rescue 0

       @answer=@answer.keys.map{|f| f.to_i}.select{|v| @answer["#{v}"]==true}.sort
       if(@answer.nil? or @answer.empty?)
          render json: {:msg => "Empty", :correct => false, :explanation => ["empty"], :detailed_exp => {}, :done => [item_pos, group_pos, @lecture.is_done]} and return
       end
       @real=OnlineAnswer.where(:online_quiz_id => @quiz, :correct => true).pluck(:id).sort{|x,y| x<=>y}
       @exp=[]#OnlineAnswer.where(:id => @answer).pluck(:explanation).sort{|x,y| x<=>y}
       @grade= @answer==@real? 1:0
       @exp2={}

      if(@grade == 0) #wrong
        @answer.each do |a|
          picked=OnlineAnswer.find(a.to_i)
            ee = picked.explanation
            ee = I18n.t('controller_msg.no_explanation') if ee ==""
          @exp2[a]=[picked.correct, ee]
        end
      else #right
        online_quiz.online_answers.each do |ans|
          ee = ans.explanation
          ee = I18n.t('controller_msg.no_explanation') if ee ==""
          @exp2[ans.id]=[ans.correct, ee]
        end
      end

       if online_quiz.inclass && answered_inclass
        quiz_grades.destroy_all
        attempt = 0
       end

      @answer.each do |a|
        OnlineQuizGrade.create(:lecture_id => params[:id], :course_id => params[:course_id], :group_id => @lecture.group_id ,:user_id => current_user.id, :online_quiz_id => @quiz, :online_answer_id => a, :grade => @grade, :in_group => answered_in_group, :inclass => answered_inclass, :attempt => attempt+1,:distance_peer => answered_distance_peer)
      end

       render json: {:msg => I18n.t('controller_msg.succefully_submitted'), :correct => @answer==@real, :explanation => @exp, :detailed_exp => @exp2, :done => [item_pos, group_pos, @lecture.is_done]}
    elsif (online_quiz.question_type.upcase=="DRAG") #drag

        quiz_grades = FreeOnlineQuizGrade.where(:user_id => current_user.id, :online_quiz_id => @quiz)
        attempt = quiz_grades.sort{|x,y| x.attempt <=> y.attempt }.last.attempt rescue 0

         correct= online_quiz.online_answers[0].answer
         @exp={}
         @exp2 = {}
         if @answer==correct #student ordered correctly
           @grade=1
           # @exp = online_quiz.online_answers[0].explanation
           online_quiz.online_answers[0].explanation.each_with_index do |explanation ,index|
            ee = explanation
            ee = I18n.t('controller_msg.no_explanation') if ee ==""
            @exp2[correct[index]] = ee
           end
           @exp[online_quiz.id] = @exp2
         else
           @grade=0
         end

        #@answer.each do |k,v|
          FreeOnlineQuizGrade.create(:lecture_id => params[:id],:course_id => params[:course_id], :group_id => @lecture.group_id , :user_id => current_user.id, :online_quiz_id => @quiz, :online_answer => @answer , :grade => @grade, :attempt => attempt+1)
        #end

       render json: {:msg => I18n.t('controller_msg.succefully_submitted'), :correct => @grade==1 , :explanation => @exp, :done => [item_pos, group_pos, @lecture.is_done] }
    elsif (online_quiz.question_type.upcase=="FREE TEXT QUESTION") #Free Text
      quiz_grades = FreeOnlineQuizGrade.where(:user_id => current_user.id, :online_quiz_id => @quiz)
      attempt = quiz_grades.sort{|x,y| x.attempt <=> y.attempt }.last.attempt rescue 0

      @exp = {}
      ee = online_quiz.online_answers[0].explanation
      ee = I18n.t('controller_msg.no_explanation') if ee ==""
      @exp[online_quiz.id] = ee
      if online_quiz.online_answers[0].answer == ""
        @grade = 0
        review = true
      else
        match_string = online_quiz.online_answers[0].answer
        if match_string =~ /^\/.*\/$/
          match_string =match_string[1..match_string.length-2]
          regex = Regexp.new match_string
          @grade =  !!(@answer =~ regex)? 3:1 
        else
          @grade = !!(@answer.downcase == match_string.downcase)? 3:1
        end
        review = false
      end
      # if FreeOnlineQuizGrade.where(:user_id => current_user.id, :online_quiz_id => @quiz).empty?
      FreeOnlineQuizGrade.create(:lecture_id => params[:id],:course_id => params[:course_id], :group_id => @lecture.group_id , :user_id => current_user.id, :online_quiz_id => @quiz, :online_answer => @answer , :grade => @grade, :attempt => attempt+1)
      # end
      render json: {:msg => I18n.t('controller_msg.succefully_submitted'), :correct => @grade==3 , :explanation => @exp, :done => [item_pos, group_pos, @lecture.is_done], :review => review}
    else #OCQ
      quiz_grades = OnlineQuizGrade.where(:user_id => current_user.id, :online_quiz_id => @quiz, :in_group => answered_in_group )
      attempt = quiz_grades.sort{|x,y| x.attempt <=> y.attempt }.last.attempt rescue 0

      if(@answer.nil? or @answer.empty?)
          render json: {:msg => "Empty", :correct => false, :explanation => ["empty"], :detailed_exp => {}, :done => [item_pos, group_pos, @lecture.is_done]} and return
      end
      @real_ans= OnlineAnswer.find(@answer.to_i)
      @grade=@real_ans.correct ? 1:0

      @exp2={}
      logger.debug("grade is #{@grade}")


      if(@grade == 0)
        ee = @real_ans.explanation
        ee = I18n.t('controller_msg.no_explanation') if ee ==""
        @exp2[@answer]=[@real_ans.correct, ee]
      else
        online_quiz.online_answers.each do |ans|
          ee= ans.explanation
          ee= I18n.t('controller_msg.no_explanation') if ee==""

          @exp2[ans.id]=[ans.correct, ee]
        end
      end



      logger.debug("grade is #{@grade}")

      if online_quiz.inclass && answered_inclass
        quiz_grades.destroy_all
        attempt = 0
      end

      # if quiz_grades.empty?
      OnlineQuizGrade.create(:lecture_id => params[:id],:course_id => params[:course_id], :group_id => @lecture.group_id , :user_id => current_user.id, :online_quiz_id => @quiz, :online_answer_id => @answer, :grade => @grade, :in_group => answered_in_group, :inclass => answered_inclass, :attempt => attempt+1,:distance_peer => answered_distance_peer)
      # elsif online_quiz.inclass && answered_inclass
      #   quiz_grades.first.update_attributes(:online_answer_id => @answer, :grade => @grade)
      # end

      render json: {:msg => I18n.t('controller_msg.succefully_submitted'), :correct => @grade, :explanation => [@real_ans.explanation], :detailed_exp => @exp2, :done => [item_pos, group_pos, @lecture.is_done]}

      # if quiz_grades.empty?
      #   OnlineQuizGrade.create(:lecture_id => params[:id], :course_id => params[:course_id], :group_id => @lecture.group_id , :user_id => current_user.id, :online_quiz_id => @quiz, :online_answer_id => @answer, :grade => @grade)
      #   render json: {:msg => t('controller_msg.succefully_submitted'), :correct => @real_ans.correct, :explanation => [@real_ans.explanation], :detailed_exp => @exp2, :done => [item_pos, group_pos, @lecture.is_done]}
      # else
      #   render json: {:msg =>t('controller_msg.already_answered_question'), :ans => a.first.online_answer_id , :correct => @real_ans.correct, :explanation => [@real_ans.explanation] , :detailed_exp => @exp2, :done => [item_pos, group_pos, @lecture.is_done]}
      # end
    end

  end

  def save_online
    @answer= params[:answer]
    @quiz_id= params[:quiz]
    quiz = OnlineQuiz.find(@quiz_id)
    ques_type=quiz.question_type
    @lecture= Lecture.find(params[:id])
    answered_inclass = params[:inclass] || false
    answered_in_group = params[:in_group] || false
    answered_distance_peer = params[:distance_peer] || false
    group=@lecture.group
    item_pos=params[:id]
    group_pos= group.id
    @lecture.current_user=current_user
    # quiz_grades = OnlineQuizGrade.where(:user_id => current_user.id, :online_quiz_id => @quiz_id, :in_group => answered_in_group)

    if quiz.inclass && answered_inclass
      views = LectureView.where(:user_id => current_user.id,  :lecture_id =>  params[:id])
      if views.empty?
        LectureView.create(:user_id => current_user.id, :group_id =>  @lecture.group_id, :course_id =>  @lecture.course_id, :lecture_id =>  params[:id], :percent => 100)
      elsif views.first && views.first.percent < 100
        views.first.update_attribute(:percent, 100)
      end
    end
    if ques_type=="MCQ"
      quiz_grades = OnlineQuizGrade.where(:user_id => current_user.id, :online_quiz_id => @quiz_id, :in_group => answered_in_group )
      attempt = quiz_grades.sort{|x,y| x.attempt <=> y.attempt }.last.attempt rescue 0
      if @answer.empty?
        render json: {:msg => "Empty", :correct => false, :explanation => ["empty"], :detailed_exp => {}, :done => [item_pos, group_pos, @lecture.is_done]} and return
      end
      @answer.map!{|e| e.to_i}
      @real=OnlineAnswer.where(:online_quiz_id => @quiz_id, :correct => true).pluck(:id).sort{|x,y| x<=>y}
      @exp=OnlineAnswer.where(:id => @answer).pluck(:explanation).sort{|x,y| x<=>y}

      @exp2={}

      if quiz.quiz_type =='survey'
        @grade = 1
      else
        @grade= @answer.sort{|x,y| x<=>y}==@real? 1:0
      end

      if(@grade == 0) #wrong
        @answer.each do |a|
          picked=OnlineAnswer.find(a.to_i)
            ee = picked.explanation
            ee = I18n.t('controller_msg.no_explanation') if ee ==""
          @exp2[a]=[picked.correct, ee]
        end
      else #right
        quiz.online_answers.each do |ans|
          ee = ans.explanation
          ee = I18n.t('controller_msg.no_explanation') if ee ==""
          @exp2[ans.id]=[ans.correct, ee]
        end
      end

      if quiz.inclass && answered_inclass
        quiz_grades.destroy_all
        attempt = 0
      end

      @answer.each do |a|
        OnlineQuizGrade.create(:lecture_id => params[:id],:course_id => params[:course_id], :group_id => @lecture.group_id , :user_id => current_user.id, :online_quiz_id => @quiz_id, :online_answer_id => a, :grade => @grade, :in_group => answered_in_group, :inclass => answered_inclass, :attempt => attempt+1,:distance_peer => answered_distance_peer)
      end
      render json: {:msg => I18n.t('controller_msg.succefully_submitted'), :correct => @grade, :explanation => @exp, :detailed_exp => @exp2, :done => [item_pos, group_pos, @lecture.is_done]}
    elsif ques_type.downcase=="drag"
      @exp=[]
      @exp2={}
      @grade=1
      if @answer.empty?
        render json: {:msg => "Empty", :correct => false, :explanation => ["empty"], :detailed_exp => {}, :done => [item_pos, group_pos, @lecture.is_done]} and return
      end

      quiz_grades = OnlineQuizGrade.where(:user_id => current_user.id, :online_quiz_id => @quiz_id, :in_group => answered_in_group)
      attempt = quiz_grades.sort{|x,y| x.attempt <=> y.attempt }.last.attempt rescue 0

      @answer.each do |k,v|
        pos=OnlineAnswer.find(k.to_i).pos
        if OnlineAnswer.find(k.to_i).answer!=v
          q=OnlineAnswer.find(k.to_i).online_quiz
          all=q.online_answers
          @grade=0

          if !all.select{|t| t.answer==v }[0].nil?
            ee= all.select{|t| t.answer==v }[0].explanation[pos]
            ee= I18n.t('controller_msg.no_explanation') if ee==""
            @exp2[k]=[false, ee]
          else
            @exp2[k]=[false, I18n.t('controller_msg.no_explanation')]
          end

          @exp<<all.select{|t| t.answer==v }[0].explanation[pos] if !all.select{|t| t.answer==v }[0].nil?
        else
          ee= OnlineAnswer.find(k.to_i).explanation[pos]
          ee= I18n.t('controller_msg.no_explanation') if ee==""

          @exp2[k]=[true, ee]
          @exp<<OnlineAnswer.find(k.to_i).explanation[pos]
        end
      end

      @answer.each do |k,v|
        OnlineQuizGrade.create(:lecture_id => params[:id],:course_id => params[:course_id], :group_id => @lecture.group_id , :user_id => current_user.id, :online_quiz_id => @quiz_id, :online_answer_id => k.to_i,:optional_text => v, :grade => @grade, :attempt => attempt+1)
      end

      render json: {:msg => I18n.t('controller_msg.succefully_submitted'), :correct => @grade==1 , :explanation => @exp, :detailed_exp => @exp2, :done => [item_pos, group_pos, @lecture.is_done]}
    elsif ques_type.downcase=="free text question"
      answers = quiz.online_answers
      # @exp = []
      # @exp = quiz.online_answers[0].explanation|| ""
      @exp = {}
      ee= quiz.online_answers[0].explanation
      ee= I18n.t('controller_msg.no_explanation') if ee==""

      @exp[quiz.id] = ee

      quiz_grades = FreeOnlineQuizGrade.where(:user_id => current_user.id, :online_quiz_id => quiz.id)
      attempt = quiz_grades.sort{|x,y| x.attempt <=> y.attempt }.last.attempt rescue 0

      if !answers.empty?
        if answers.first.answer.blank?
          @grade = 0
          review = true
        else
          match_string = answers.first.answer
          if match_string =~ /^\/.*\/$/
            match_string =match_string[1..match_string.length-2]
            regex = Regexp.new match_string
            @grade =  !!(@answer =~ regex)? 1:0
          else
            @grade = !!(@answer.downcase == match_string.downcase)? 1:0
          end
          review = false
        end

        FreeOnlineQuizGrade.create(:lecture_id => params[:id],:course_id => params[:course_id], :group_id => @lecture.group_id , :user_id => current_user.id, :online_quiz_id => quiz.id, :online_answer => @answer , :grade => @grade, :attempt => attempt+1)
        render json: {:msg => I18n.t('controller_msg.succefully_submitted'), :correct => @grade==1 , :explanation => @exp, :done => [item_pos, group_pos, @lecture.is_done], :review => review}

      end
    else #OCQ

      quiz_grades = OnlineQuizGrade.where(:user_id => current_user.id, :online_quiz_id => @quiz_id, :in_group => answered_in_group)
      attempt = quiz_grades.sort{|x,y| x.attempt <=> y.attempt }.last.attempt rescue 0

      if @answer.nil? or @answer.blank?
        render json: {:msg => "Empty", :correct => false, :explanation => ["empty"], :detailed_exp => {}, :done => [item_pos, group_pos, @lecture.is_done]} and return
      end

      @real_ans= OnlineAnswer.find(@answer)
      if quiz.quiz_type =='survey'
        @grade = 1
      else
        @grade= @real_ans.correct ? 1:0
      end

      @exp2={}

      if(@grade == 0)
          ee= @real_ans.explanation
          ee= I18n.t('controller_msg.no_explanation') if ee==""

        @exp2[@answer]=[@real_ans.correct, ee]
      else
        quiz.online_answers.each do |ans|
          ee= ans.explanation
          ee= I18n.t('controller_msg.no_explanation') if ee==""

          @exp2[ans.id]=[ans.correct, ee]
        end
      end

      if quiz.inclass && answered_inclass
        quiz_grades.destroy_all
        attempt = 0
      end

      # if quiz_grades.empty?
      OnlineQuizGrade.create(:lecture_id => params[:id],:course_id => params[:course_id], :group_id => @lecture.group_id , :user_id => current_user.id, :online_quiz_id => @quiz_id, :online_answer_id => @answer, :grade => @grade, :in_group => answered_in_group, :inclass => answered_inclass, :attempt => attempt+1,:distance_peer => answered_distance_peer)
      # elsif quiz.inclass && answered_inclass
      #   quiz_grades.first.update_attributes(:online_answer_id => @answer, :grade => @grade)
      # end

      render json: {:msg => I18n.t('controller_msg.succefully_submitted'), :correct => @grade, :explanation => [@real_ans.explanation], :detailed_exp => @exp2, :done => [item_pos, group_pos, @lecture.is_done]}
    end
  end

	def confused #can be atmost confused twice within 15 seconds. when once -> very false, when twice -> very true, if more will not save and alert you to ask a question instead.

			x=0
			#check first if more more than 2 already.. then don't add a new one.
			user_confused= Confused.where(:lecture_id => params[:id], :course_id => params[:course_id], :user_id => current_user.id)
			user_confused_rounded= Confused.get_rounded_time_check(user_confused)
			current_confused_rounded= Time.zone.parse(Time.seconds_to_time(params[:time].to_i)).floor(15.seconds).to_i

			@msg=""
			flag=false
			user_confused_rounded.each do |key,value|
					if key==current_confused_rounded  #if not here then this will be the first time.
							flag=true
							x=Confused.find(value[1])
							if value[0]==1 and x.very == false #only done it once before.
									x.update_attributes(:very => true) #now twice.
									@message=I18n.t('groups.saved')
							elsif value[0]=1 and x.very == true #done it twice before
									#will not create a new one, just notify them that they could ask a question instead.
									@message="ask"#t('controller_msg.really_confused_use_question')
							end
					end
			end

			if flag==false #not confused before in this 15 sec interval.
					x=Confused.new(:lecture_id => params[:id], :course_id => params[:course_id], :user_id => current_user.id, :time => params[:time], :very => false)
					if x.save
						@message=I18n.t('groups.saved')
					else
						@message=x.errors
					end
			end
			#should probably rescue if an exception occurs.
			render json: {:msg => @message, :flag => flag, :id => x.id, :item => x}
	end

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
	  lecture_url_not_used_elsewhere = Lecture.where(:url=>@lecture.url).count==1
		ActiveRecord::Base.transaction do
			lec_destory = @lecture.destroy
			if (lecture_url_not_used_elsewhere && is_vimeo(@lecture))
				delete_vimeo_video
			end	
		end
		if lec_destory
			## waitin for shared item table
			SharedItem.delete_dependent("lecture",params[:id].to_i, current_user.id)
			Forum::Post.delete("destroy_all_by_lecture", {:lecture_id => params[:id]})
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
		@lecture = @course.lectures.build(:name => "New Lecture", :appearance_time => group.appearance_time, :due_date => group.due_date, 
				:appearance_time_module => true, :due_date_module => true, :required_module => true, 
				:graded_module => true, :skip_ahead_module => true,:url => "none", 
				:group_id => params[:group], :slides => "none", :position => position, 
				:start_time => 0, :end_time => 0, :inclass => params[:inclass] ,
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
		marker = @lecture.online_markers.build(:group_id => @lecture.group_id, :course_id => @lecture.course_id, :title => "", 
				:annotation => "", :time => params[:marker][:time], 
				:height => params[:marker][:height],  :width => params[:marker][:width],  
				:xcoor => params[:marker][:xcoor],  :ycoor => params[:marker][:ycoor], :as_slide => params[:marker][:as_slide] ) 
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
			render json: {errors: [I18n.t('controller_msg.no_such_lecture')]}, :status => 404 and return
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
		day= I18n.t("controller_msg.#{day2}")

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

	def delete_confused
			c=@lecture.confuseds.where(:id => params[:confused_id], :user_id => current_user.id)[0]
			if c.destroy
					render json: {:notice => [I18n.t("controller_msg.successfully_deleted")]}
			else
					render json: {:errors => [I18n.t("controller_msg.could_not_delete_confused")]}, :status => 400
			end
	end

	def save_note
			lecture= Lecture.find(params[:id])
			if params[:note_id]
				note = lecture.video_notes.find(params[:note_id])
				if note.update_attributes(:data => params[:data])
					render json: {:notice => I18n.t('notes.successfully_saved'),:note => note}
				else
					render json: {errors:note.errors.full_messages}, status: 400
				end
			else
				note = lecture.video_notes.build(:user_id => current_user.id, :data => params[:data], :time => params[:time])
				if note.save
					render json: {:notice => I18n.t('notes.successfully_saved'),:note => note}
				else
					render json: {errors:lecture.errors.full_messages}, status: 400
				end
			end
		
	end

	def delete_note
			note=@lecture.video_notes.find(params[:note_id])
			if note.destroy
					render json: {:notice => [I18n.t("notes.successfully_deleted")]}
			else
					render json: {:errors => [I18n.t("notes.could_not_delete_note")]}, :status => 400
			end
	end

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
		copy_lecture.skip_ahead_module = true


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

	def export_notes
    notes = []
    @group_no = Lecture.where(:id => params[:id]).pluck(:group_id)
    lectures = Lecture.where(:group_id => @group_no)
    lectures.each do |l|
      if l.video_notes.any?
        notes << VideoNote.where(:lecture_id => l.id, :user_id => current_user.id).to_json(:include => {:lecture => {:only => [:name, :id]}})
      end
    end
    if notes.nil?
      render json: {:notes => "", :exists => false}
    else
      render json: {:notes => notes, :exists => true}
    end
	end

  def change_status_angular
   status=params[:status].to_i
   assign= @lecture.assignment_item_statuses.where(:user_id => params[:user_id]).first
   if !assign.nil?
     #0 original
     (status == 0)? assign.destroy : assign.update_attributes(:status => status)
   elsif status!=0
     @lecture.assignment_item_statuses<< AssignmentItemStatus.create(:user_id => params[:user_id], :course_id => params[:course_id], :status => status ,  :group_id =>@lecture.group.id , :lecture_id => params[:id])
   end

   render :json => {:success => true, :notice => [I18n.t("courses.status_successfully_changed")]}
  end
	
	def confused_show_inclass
			start_time = params[:time] - (params[:time]%15)
			end_time = start_time + 14.99
			@lecture.confuseds.where("time between ? and ?",start_time ,end_time).update_all(:hide => params[:hide])
			render :json => {}
	end

	def check_if_invited_distance_peer
			course=Course.find(params[:course_id])

			invatations = current_user.user_distance_peers.includes(:distance_peer).select{|d| d.distance_peer.lecture_id == params[:id].to_i  && d.status ==0}
			if invatations.select { |d| current_user.id != d.distance_peer.user_id }.count != 0
					online_names = invatations.map{|u_dis| [u_dis.distance_peer.user.screen_name ,  u_dis.distance_peer.id]}
					render json: {:invite => online_names ,:invite_status=>"invited_by" }
			elsif invatations.select { |d| current_user.id == d.distance_peer.user_id }.count == 1
					online_names =  DistancePeer.find(invatations.first.distance_peer_id).user_distance_peers.select{|d| d.status ==0 && current_user.id != d.user_id}.map{|u_dis| u_dis.user.screen_name }
					render json: {:invite => online_names[0] ,:invite_status=>"invited" , :distance_peer_id => invatations.first.distance_peer_id }
			else
					students = course.enrolled_students.select("users.email,users.last_name,users.name, LOWER(users.name)").order("LOWER(users.name)") #enrolled
					students.each do |s|
							s[:full_name] = s.full_name
							s[:email] = s.email
					end
					students = students.select{|s| s.email != current_user.email}

					render json:{ :invite_status => "no_invitation", :students => students}
			end
	end

	def check_if_in_distance_peer_session
		session = current_user.user_distance_peers.includes(:distance_peer).order('updated_at DESC').select{|d| d.distance_peer.lecture_id == params[:id].to_i && !(d.status == 0 || d.status == 6 )}
		
		if session.count != 0
			distance_peer = DistancePeer.find(session.first.distance_peer_id).user_distance_peers 
      user_distance_peer = distance_peer.select{|d| current_user.id == d.user_id}[0] 
      other_user_distance_peer = distance_peer.select{|d| current_user.id != d.user_id}[0] 
      online_names =  other_user_distance_peer.user.screen_name  
 
      if user_distance_peer.status != other_user_distance_peer.status && (user_distance_peer.updated_at > other_user_distance_peer.updated_at ) 
        # status = "wait" 
        render json: {:distance_peer => other_user_distance_peer ,:name => online_names } 
      else 
        render json: {:distance_peer => user_distance_peer ,:name => online_names } 
      end 
      # render json: {:distance_peer => session.first, :user_distance_peer => user_distance_peer ,:name => online_names } 
		else
			render json:{ :distance_peer => "no_peer_session"}
		end
  	end

	def invite_student_distance_peer
			@lecture= Lecture.find(params[:id])
			user_distance_peer = current_user.user_distance_peers.includes(:distance_peer).select{|d| d.distance_peer.lecture_id == params[:id].to_i  && d.status ==0 && d.distance_peer.user_id == User.find_by_email(params[:email]).id }
			if user_distance_peer.select { |d| current_user.id != d.distance_peer.user_id }.count != 0
					distance_peer = user_distance_peer.first.distance_peer
					distance_peer.user_distance_peers.update_all(status: 1)

			else
					distance_peer = DistancePeer.create(:user_id => current_user.id, :course_id => params[:course_id] ,  :group_id =>@lecture.group.id , :lecture_id => params[:id])
					UserDistancePeer.create(:distance_peer_id=>distance_peer.id , :user_id => User.find_by_email(params[:email]).id, :status => 0 ,  :online =>false )
					UserDistancePeer.create(:distance_peer_id=>distance_peer.id , :user_id => current_user.id, :status => 0 ,  :online =>false )
			end
			render json: {:notice => "wait_for_student" , :distance_peer_id => distance_peer.id}
	end

	def check_invited_student_accepted_distance_peer
			user = User.find_by_email(params[:email])
			status = nil
			if user
					status = UserDistancePeer.find_by_distance_peer_id_and_user_id(params[:distance_peer_id] , user.id)
			# else
					# render json: {:status => "no_peer_session"}
			end
			if status
					render json: {:status => status.status}
			else
					render json: {:status => "denied"}
			end
	end

	def accept_invation_distance_peer
			if DistancePeer.exists?(id: params[:distance_peer_id])
					DistancePeer.find(params[:distance_peer_id]).user_distance_peers.update_all(status: 1)
					# UserDistancePeer.find_by_distance_peer_id(params[:distance_peer_id])
					render json: {:status => 0}
			else
					render json: {:status => "cancelled"}
			end
	end

	def cancel_session_distance_peer
			if DistancePeer.exists?(id: params[:distance_peer_id])
					DistancePeer.find(params[:distance_peer_id]).destroy
			end
			render json:{:distance_peer=> 'deleted'}
	end

	def change_status_distance_peer
			session = UserDistancePeer.includes(:distance_peer).select{|d| d.distance_peer_id == params[:distance_peer_id].to_i && d.user_id == current_user.id}
			if session.count != 0
					if params[:online_quiz_id]=="do_not_updated"
							session.first.update_attributes(:status => params[:status])
					else
							session.first.update_attributes(:status => params[:status],:online_quiz_id=> params[:online_quiz_id])
					end
					render json: {:status =>  "done" }
			else
					render json:{ :distance_peer => "no_peer_session"}
			end

	end

	def check_if_distance_peer_status_is_sync
			session = UserDistancePeer.includes(:distance_peer).select{|d| d.distance_peer_id == params[:distance_peer_id].to_i }
			user_student = session.select{|d| d.user_id == current_user.id}
			second_student = session.select{|d| d.user_id  != current_user.id}
			if session.count == 2
					if ( user_student.first.status == second_student.first.status )# && (second_student.first.status != 6)
							render json: {:status =>  "start" }
					else
							render json:{ :status => "wait"}
					end
			else
					render json:{ :distance_peer => "no_peer_session"}
			end
	end

	def check_if_distance_peer_is_alive
			session = UserDistancePeer.includes(:distance_peer).select{|d| d.distance_peer_id == params[:distance_peer_id].to_i }
			user_student = session.select{|d| d.user_id == current_user.id}
			second_student = session.select{|d| d.user_id  != current_user.id}
			if session.count == 2
					if second_student.first.status == 6
							user_student.first.update_attributes(:status => 6)
							render json: {:status =>  "dead" }
					else
							render json:{ :status => "alive"}
					end
			else
					render json:{ :distance_peer => "no_peer_session"}
			end
	end

	def is_vimeo(lecture)
		if lecture.url.include?('vimeo.com/')
			return true 
		else	
			return false
		end
	end	
	
	def extract_upload_details(response)
		video_info_access_token="b97fb8ab110c5aa54f73267911fc5051"#<<<<<<<<<----------env var
		parsed_response = JSON.parse(response)
		vimeo_video_id = parsed_response['uri'].split('videos/')[1]
		upload_link = parsed_response['upload']['upload_link']
		ticket_id = upload_link.match(/\?ticket_id=[0-9]*/)[0].split('=')[1]
		video_file_id = upload_link.match(/\&video_file_id=[0-9]*/)[0].split('=')[1]
		signature = upload_link.match(/\&signature=([0-9]*[a-zA-Z]*)*/)[0].split('=')[1]
		complete_url ='https://api.vimeo.com/users/96206044/uploads/'+ticket_id+'?video_file_id='+video_file_id+'&upgrade=true&signature='+signature
		details = {'complete_url':complete_url,'ticket_id':ticket_id,'upload_link_secure':upload_link,'video_id':vimeo_video_id,'video_info_access_token':video_info_access_token}
		return details
	end	

	def get_vimeo_upload_details
		retries = 3 
		delay = 1 
		begin
			response = HTTParty.post('https://api.vimeo.com/me/videos',headers:{"Authorization"=>"bearer e6783970f529d6099598c4a7357a9aae","Content-Type"=>"application/json","Accept"=>"application/vnd.vimeo.*+json;version=3.4"})	
		rescue ex
			fail "All retries are exhausted" if retries == 0
			puts "get_vimeo_upload_details Request failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
		end	
		details = extract_upload_details(response)
		if response.code == 201 
			render json: {details:details, :notice => ["upload details is retreived successfully"]}
		else
			render json: {:errors => response['developer_message']}, status: 400
		end
	end	

	def delete_complete_link
		ENV['vimeo_token']='e6783970f529d6099598c4a7357a9aae'
		retries = 3 
		delay = 1 
		begin
		response = HTTParty.delete(params[:link],headers:{"Authorization"=>"bearer "+ENV['vimeo_token']})
		rescue ex
			fail "All retries are exhausted" if retries == 0
			puts "delete_complete_link Request failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
		end	
		if response.code == 201
			puts ">>>>>>>>>>>>>>>>>delete comeplete link is done <<<<<<<<<<<<<<<<<"
			render json:{deletion:response, :notice => ["complete link deletion is done successfully"]}
		else 
			render json: {:errors => resposne['the completion link is not deleted']}, status:400
		end		
	end	

	def delete_vimeo_video
		vid_vimeo_id = @lecture.url.split('https://vimeo.com/')[1]
		delete_video_from_vimeo_account(vid_vimeo_id)
		delete_video_upload_record(vid_vimeo_id) 
	end	

	def delete_vimeo_video_angular				
		vid_vimeo_id = params['vimeo_vid_id']
		state = delete_video_from_vimeo_account(vid_vimeo_id)
		delete_video_upload_record(vid_vimeo_id) 
		@lecture.update(url:"none")
		@lecture.update(duration:0)
		if state == true 
			render json:{ deletion:state ,:notice => ["video deletion is done successfully"]}		
		else 	 
			render json:{ :notice => ["video is not delete"]}	
		end	
	end	

	def update_vimeo_video_data
		retries = 3 
		delay = 1 
		
		ENV['vimeo_token']='e6783970f529d6099598c4a7357a9aae'
		video_edit_url = 'https://api.vimeo.com/videos/'+params[:video_id]
		authorization = {"Authorization"=>"bearer "+ENV['vimeo_token']}
		body = {name:params[:name],description:params[:description]}
		begin 
		 response=HTTParty.patch(video_edit_url,headers:authorization,body:body)
		rescue ex
			fail "All retries are exhausted" if retries == 0
			puts "update_vimeo_video_data failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
		end	
		if response.code == 200	
			puts ">>>>>>>>>video data updated<<<<<"
			render json: { video_update:response, :notice => ["update video name on vimeo is done successfully"]}
		else 
			render json: {:errors => response['video name on vimeo is not updated']}, status:400
		end		
		
	end	

private
	def lecture_params
		params.require(:lecture).permit(:course_id, :description, :name, :url, :group_id, :appearance_time, :due_date, :duration,
			:aspect_ratio, :slides, :appearance_time_module, :due_date_module,:required_module , :inordered_module, 
			:position, :required, :inordered, :start_time, :end_time, :type, :graded, :graded_module, :inclass, :distance_peer,
			:skip_ahead,:skip_ahead_module)
	end

	def delete_video_from_vimeo_account(vid_vimeo_id)
		#clean up SL vimeo account
		retries = 3
		delay = 1 
		ENV["VIMEO_DELETION_TOKEN"]="e6783970f529d6099598c4a7357a9aae"
		begin			
			vimeo_video = VimeoMe2::Video.new(ENV["VIMEO_DELETION_TOKEN"],vid_vimeo_id)	
			vimeo_video.destroy	
			state = true
		rescue 	VimeoMe2::RequestFailed
			puts "video already deleted form the SL vimeo account"
			state = false
		rescue Rack::Timeout::RequestTimeoutException
			fail "All retries are exhausted" if retries == 0
			puts "Video deletion Request failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
			state = false
		end	
		return state
	end	
	
	def delete_video_upload_record(vid_vimeo_id)
		#clean up VimeoUpload table
		vimeo_upload_record = VimeoUpload.find_by_vimeo_url("https://vimeo.com/"+vid_vimeo_id.to_s)
		vimeo_upload_record.destroy if vimeo_upload_record	
	end	

end