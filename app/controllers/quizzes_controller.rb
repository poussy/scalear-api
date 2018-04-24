class QuizzesController < ApplicationController

  load_and_authorize_resource

  before_action :set_zone
  before_action :correct_id

  def set_zone
    @course=Course.find(params[:course_id])
    Time.zone= @course.time_zone
  end

  def correct_id
    if params[:id]
      @quiz = Quiz.where(:id => params[:id], :course_id => params[:course_id])[0]
      if @quiz.nil?
        render json: {:errors => [I18n.t("controller_msg.no_such_quiz")]}, :status => 404
      end
    end
  end

  def new_or_edit #called from course_editor / module editor to add a new quiz
    group = Group.find(params[:group])
    items = group.get_items
    position = 1
    if !items.empty?
      position = items.last.position + 1
    end
    if params[:type]=="quiz"
      @quiz = @course.quizzes.build(:name => "New Quiz", :instructions =>  I18n.t('groups.choose_correct_answer'), :appearance_time => group.appearance_time+100.years  , :due_date => group.due_date ,:appearance_time_module => false, :due_date_module => true, :required_module => true, :graded_module => true,:group_id => params[:group], :quiz_type =>"quiz", :retries => 0, :position => position , :required=>group.required , :graded=>group.graded)
    else
      @quiz = @course.quizzes.build(:name => "New Survey", :instructions => I18n.t('groups.fill_in_survey'), :appearance_time => group.appearance_time+100.years , :due_date => group.due_date ,:appearance_time_module => false, :due_date_module => true, :required_module => true, :graded_module => true,:group_id => params[:group], :quiz_type => "survey", :retries => 0, :position => position , :required=>group.required , :graded=>group.graded)
    end
    @quiz['class_name']='quiz'
    if @quiz.save
      render json: {quiz:@quiz, :notice => [I18n.t("controller_msg.#{@quiz.quiz_type}_successfully_created")]}
    else
      render json: {:errors => @quiz.errors}, status: 400
    end
  end

  def get_questions_angular
    quiz= Quiz.find(params[:id])
    questions= quiz.questions


    questions.sort {|x,y| ( x.position and y.position ) ? x.position <=> y.position : ( x.position ? -1 : 1 )  }
    answers=[]
    s_grades={}
    status=""
    drag_origin_answer=''
    correct={}
    explanation={}
    questions.each_with_index do |q, index|
      if quiz.course.is_student(current_user)
        answers[index]=q.answers.select([:id, :question_id, :content,:explanation])
        if q.question_type.upcase=="DRAG"
          drag_origin_answer =  q.answers[0].content.clone
          answers[index].each do |a|
              a.content.shuffle!
          end
        end

        #getting student answers, grades
        grades=current_user.quiz_grades.where(:quiz_id => params[:id], :question_id => q.id).pluck(:answer_id)
        correct1= current_user.quiz_grades.where(:quiz_id => params[:id], :question_id => q.id)[0]
        free_answers=current_user.free_answers.where(:quiz_id => params[:id], :question_id => q.id)
        
        if q.question_type=="MCQ" && !grades.empty?
          s_grades[q.id]={}
          grades.each do |a| 
            s_grades[q.id][a]=true #112:{186:true,187:true} selected answers
            explanation[a] = answers[index].select{|ans|ans.id == a}[0].explanation if quiz.show_explanation #add explanations for selected answer
          end
          correct[q.id]=correct1.grade if !correct1.nil?
          answers[index].each{|ans| explanation[ans.id] = ans.explanation} if correct[q.id] == 1.0 #add all explanations if answer is correct
        elsif q.question_type=="OCQ" && !grades.empty?
          s_grades[q.id]=grades[0] #111: 190 selected answer
          explanation[grades[0]]=answers[index].select{|ans|ans.id == grades[0]}[0].explanation if quiz.show_explanation #add explanation for selected answer
          correct[q.id]=correct1.grade if !correct1.nil?
          answers[index].each{|ans| explanation[ans.id] = ans.explanation} if correct[q.id] == 1.0 #add all explanations if answer is correct
          
        elsif q.question_type.upcase=="DRAG" && !free_answers.empty?
          exp=[]
          free_answers[0].answer.each do |drag|
            exp.append(q.answers[0].explanation[drag_origin_answer.index(drag)])
          end
          explanation[q.answers[0].id]=exp if free_answers[0].grade == 1 
          s_grades[q.id]=free_answers[0].answer
          correct[q.id]=free_answers[0].grade
        elsif q.question_type.upcase=="FREE TEXT QUESTION" && !free_answers.empty?
          explanation[q.answers[0].id] = q.answers[0].explanation if free_answers[0].grade == 3 || free_answers[0].grade == 2
          s_grades[q.id]=free_answers[0].answer
          correct[q.id]=free_answers[0].grade
        end
      
        # remove explanations from answers
        if q.question_type.upcase=="DRAG"
          answers[index][0].explanation = []
        else
          answers[index].each do |answer|
            answer.explanation = nil
          end
        end

      else
        if q.question_type == "Free Text Question" && q.quiz.quiz_type != "survey"
          if q.answers[0].content != ""
            q[:match_type] = "Match Text"
          else
            q[:match_type] = "Free Text"
          end
        end
        answers[index]=q.answers
      end
    end


    # returning status
    status= current_user.quiz_statuses.where(:quiz_id => params[:id], :course_id => params[:course_id])[0]
    if quiz.course.is_student(current_user)
      correct={} if status.nil? or status.status!="Submitted"
      explanation={} if status.nil? or status.status!="Submitted"
    end

    @alert_messages=get_alert_messages(quiz,status)

    quiz.current_user=current_user
    if quiz.is_done
      next_i = quiz.group.next_item(quiz.position)
      next_item={}
      if !next_i.nil?
        next_item[:id] = next_i.id
        next_item[:class_name] = next_i.class.name.downcase
        next_item[:group_id] = next_i.group.id
      end
    else
      next_item=nil
    end
    today = Time.zone.now
    all = quiz.group.lectures.select{|v| v.appearance_time <= today || v.inclass } +  quiz.group.quizzes.select{ |v| v.appearance_time <= today}
    all.sort!{|x,y| ( x.position and y.position ) ? x.position <=> y.position : ( x.position ? -1 : 1 )  }
    requirements={:lecture => [], :quiz => []}
    if quiz.required
      all.each do |l|
        if l.id == quiz.id
          break
        elsif l.required && l.graded
          requirements[l.class.name.downcase.to_sym] << l.id
        end
      end
    end
    quiz[:requirements] = requirements


    render :json => {:quiz =>quiz,:next_item => next_item,  :questions => questions, :answers => answers, 
      :quiz_grades => s_grades, :status => status, :correct => correct, 
      :explanation => explanation , :alert_messages=>@alert_messages}
  end

  def get_alert_messages(quiz,status)
    @alert_messages={}
    day2='day'.pluralize((Time.zone.now.to_date - quiz.due_date.to_date).to_i)
    if quiz.due_date < Time.zone.now #if due date 5 april (night) then i have until 6 april..
      @alert_messages['due']= [I18n.localize(quiz.due_date, :format => '%d %b'), (Time.zone.now.to_date - quiz.due_date.to_date).to_i, I18n.t("controller_msg.#{day2}")]
    elsif  quiz.due_date.to_date == Time.zone.today && Time.zone.now.hour <= quiz.due_date.hour
      @alert_messages['today'] = quiz.due_date
    end
    @alert_messages['submit']= true if !status.nil? and status.status=="Submitted" and status.attempts==quiz.retries+1#"You've submitted the "+" #{quiz.quiz_type.capitalize} " + t('controller_msg.no_more_attempts')
    return @alert_messages
  end

  def update
    @quiz = Quiz.find(params[:id])
    group = @quiz.group
    @course = Course.find(params[:course_id])
    if params[:quiz][:due_date_module] == true
       params[:quiz][:due_date]=group.due_date
    end
    if params[:quiz][:appearance_time_module]==true
      params[:quiz][:appearance_time]=group.appearance_time
    end
    if params[:quiz][:required_module]== true
      params[:quiz][:required]=group.required
    end
    if params[:quiz][:graded_module]== true
      params[:quiz][:graded]=group.graded
    end
    if @quiz.update_attributes(quiz_params)
       @quiz.events.where(:lecture_id => nil, :group_id => group.id).destroy_all
       if @quiz.due_date.to_formatted_s(:long) != group.due_date.to_formatted_s(:long)
           @quiz.events << Event.new(:name => "#{@quiz.name} "+I18n.t('controller_msg.due'), :start_at => params[:quiz][:due_date], :end_at => params[:quiz][:due_date], :all_day => false, :color => "red", :course_id => @course.id, :group_id => group.id)
       end
       render json: {quiz: @quiz.remove_null_virtual_attributes, :notice => [I18n.t("controller_msg.#{@quiz.quiz_type}_successfully_updated")] }
    else
      render json: {:errors => @quiz.errors , :appearance_time =>@quiz.appearance_time.strftime('%Y-%m-%d') }, :status => :unprocessable_entity
    end
  end

  def quiz_copy
    id = params[:id] || params[:quiz_id]
    old_quiz = Quiz.find(id)
    new_group = Group.find(params[:module_id])
    copy_quiz= old_quiz.dup
    copy_quiz.course_id= params[:course_id]
    copy_quiz.group_id = params[:module_id]
    copy_quiz.position = new_group.get_items.size+1
    copy_quiz.save(:validate => false)

    copy_quiz.appearance_time = new_group.appearance_time
    copy_quiz.due_date = new_group.due_date
    copy_quiz.appearance_time_module = true
    copy_quiz.due_date_module = true
    copy_quiz.required_module = true
    copy_quiz.graded_module = true
    Event.where(:quiz_id => old_quiz.id, :lecture_id => nil).each do |e|
      new_event= e.dup
      new_event.quiz_id = copy_quiz.id
      new_event.course_id = copy_quiz.course_id
      new_event.group_id = copy_quiz.group_id
      new_event.save(:validate => false)
    end

    old_quiz.questions.each do |question|
      new_question = question.dup
      new_question.quiz_id = copy_quiz.id
      new_question.save(:validate => false)
      question.answers.each do |answer|
        new_answer = answer.dup
        new_answer.question_id = new_question.id
        new_answer.save(:validate => false)
      end
    end

    render json:{quiz: copy_quiz, :notice => [I18n.t("controller_msg.#{copy_quiz.quiz_type}_successfully_created")]}
  end


  def validate_quiz_angular
    # @quiz= Quiz.find(params[:id])
    if params[:quiz]
      params[:quiz].each do |key, value|
        @quiz[key]=value
      end
    end

    if @quiz.valid?
      render json:{ :nothing => true }
    else
      render json: {errors:@quiz.errors.full_messages}, status: :unprocessable_entity 
    end

  end

  def destroy
    quiz_type=@quiz.quiz_type
    @course = params[:course_id]

    if @quiz.destroy
      SharedItem.delete_dependent("quiz", params[:id].to_i, current_user.id)
      render json: {:notice => [I18n.t("controller_msg.#{quiz_type}_successfully_deleted")]}
    else
      render json: {:errors => [I18n.t("quizzes.could_not_delete_quiz")]}, :status => 400
    end
  end

  # def handle_exception(exception)
  # end
  
  # def correct_user
  # end
  
  # def set_zone
  # end
  
  # def index
  # end
  
  # def show
  # end
  
  # def new
  # end
  
  def show_question_inclass  #updating a survey question (hidden or not)
    ques_id= params[:question]
    show = params[:show]
    if show
      visible=I18n.t("visible")
    else
      visible=I18n.t("hidden")
    end
    to_update=Question.find(ques_id)
    if to_update.update_attributes(:show => show)
      render :json => {:notice => ["#{I18n.t('controller_msg.question_successfully_updated')} - #{I18n.t('now')} #{visible}"]}
    else
      render :json => {:errors => [I18n.t("quizzes.could_not_update_question")]}, :status => 400
    end
  end
  
  def show_question_student  #updating a survey question (hidden or not)
    ques_id= params[:question]
    show = params[:show]
    if show
      visible=I18n.t("visible")
    else
      visible=I18n.t("hidden")
    end
    to_update=Question.find(ques_id)
    if to_update.update_attributes(:student_show => show)
      render :json => {:notice => ["#{I18n.t('controller_msg.question_successfully_updated')} - #{I18n.t('now')} #{visible}"]}
    else
      render :json => {:errors => [I18n.t("quizzes.could_not_update_question")]}, :status => 400
    end
  end

  def create_or_update_survey_responses
    groups=params[:groups]
    response=params[:response]
    if response.blank?
      FreeAnswer.where({:id => groups}).update_all({:response => response})
      render :json => {:notice => [I18n.t("controller_msg.response_successfully_deleted")]}
    else
      FreeAnswer.where(:id => groups).update_all({:response => response})
      survey = Quiz.find(params[:id]).name
      groups.each do |g|
        answer=FreeAnswer.find(g)
        UserMailer.delay.survey_email(answer.user_id,Question.find(answer.question_id).content,answer.answer,survey,@course,response, I18n.locale)#.deliver
      end
      render :json => {:notice => [I18n.t("controller_msg.response_saved")]}
    end
  end
  
  def hide_responses
      if params[:hide]["hide"]
        hidden=I18n.t("hidden")
      else
        hidden=I18n.t("visible")
      end

      if FreeAnswer.find(params[:hide]["id"]).update_attributes(:hide => params[:hide]["hide"])
        render :json => {:notice => ["#{I18n.t('controller_msg.response_is_now')} #{hidden}"]}
      else
        render :json => {:errors => [I18n.t("quizzes.could_not_update_response")]}, :status => 400
      end
  end
  
  def hide_response_student
    if params[:hide]["hide"]
      hidden=I18n.t("hidden")
    else
      hidden=I18n.t("visible")
    end
    if FreeAnswer.find(params[:hide]["id"]).update_attributes(:student_hide => params[:hide]["hide"])
      render :json => {:notice => ["#{I18n.t('controller_msg.response_is_now')} #{hidden}"]}
    else
      render :json => {:errors => [I18n.t("quizzes.could_not_update_response")]}, :status => 400
    end
  end
  
  def delete_response
      answer=params[:answer]
      if FreeAnswer.find(answer).update_attributes(:response => "")
        render :json => {:notice => [I18n.t("controller_msg.response_successfully_deleted")]}
      else
        render :json => {:errors => [I18n.t("controller_msg.could_not_delete_response")]}, :status => 400
      end
  end
  
  def make_visible
    if params[:visible]
      hidden=I18n.t("visible")
    else
      hidden=I18n.t("hidden")
    end
    x=Quiz.find(params[:id])
    if x.update_attributes(:visible => params[:visible], :retries =>0)
      msg= I18n.t("controller_msg.#{x.quiz_type}_is_now")
      render :json => {:notice => ["#{msg} #{hidden}"]}
    else
      render :json => {:errors => [I18n.t("controller_msg.could_not_update_#{x.quiz_type}")]}, :status => 400
    end
  end
    
  def update_questions_angular

    @questions = params[:questions]

    Quiz.transaction do
      #want to update existing records. (for questions and answers)
      # want to create new ones //
      # want to delete ones no longer there.//
      old_questions=[]
      old_answers=[]
      if !@questions.nil?

        @questions.each_with_index do |new_q, index|
          if !new_q["id"].nil? #old one
            
            old_questions<<new_q["id"].to_i
            @current_q=Question.find(new_q["id"])

            z= @current_q.update_attributes!(:content => new_q["content"], :question_type => new_q["question_type"], :position => index+1)
            if !new_q["answers"].nil?
             
              if(@current_q.question_type == "Free Text Question" && new_q["match_type"] =='Free Text')
                  @current_q.answers.each do |ans|
                    ans.destroy
                  end
                  
                  new_q["answers"].each do |new_ans|
                    y = @current_q.answers.create(:content =>"" , :correct => new_ans["correct"],:explanation => new_ans["explanation"])
                    old_answers<<y.id.to_i
                  end
              else
                new_q["answers"].each do |new_ans| ######### ANSWERS #########
                  if !new_ans["id"].nil? #old one
                    old_answers<<new_ans["id"].to_i
                    Answer.find(new_ans["id"]).update_attributes!(:content => new_ans["content"], :correct => new_ans["correct"],:explanation => new_ans["explanation"])
                  else
                    y=@current_q.answers.create(:content => new_ans["content"], :correct => new_ans["correct"],:explanation => new_ans["explanation"])
                    old_answers<<y.id.to_i
                  end
                end
              end
            end
          else #new one
            x=@quiz.questions.create(:content => new_q["content"], :question_type =>new_q["question_type"], :position => index+1)
            old_questions<<x.id.to_i
            if !new_q["answers"].nil?
              new_q["answers"].each do |new_ans|
                y=x.answers.create(:content => new_ans["content"], :correct => new_ans["correct"],:explanation => new_ans["explanation"])
                old_answers<<y.id.to_i
              end
            end
          end
        end
      else
        old_questions=[]
        old_answers=[]
      end
      to_delete_a=[]
      @quiz.questions.each do |q|
        to_delete_a<<q.answers.pluck(:id)
      end
      to_delete_a.flatten!
      to_delete_a = to_delete_a - old_answers
      to_delete_a.each do |d|
        Answer.find(d).destroy
      end
      to_delete= @quiz.questions.pluck(:id) - old_questions
      to_delete.each do |d|
        Question.find(d).destroy
      end
      render :json => {:message => "success", :notice => [I18n.t("controller_msg.#{@quiz.quiz_type}_successfully_saved")]} and return
    end
    render :json => {:errors => [I18n.t("controller_msg.transaction_rolled_back")]}, :status => 400
  end

  def save_student_quiz_angular
    return_value=""
    correct_ans={}
    temp_explanation = {}
    explanation = {}
     #if submitting, must make sure all questions were solved
    group=@quiz.group
    item_pos=@quiz.id# group.quizzes.index(@quiz)
    group_pos= group.id#group.course.groups.index(group)
    @quiz.current_user=current_user
    #put transaction here
    Quiz.transaction do

      params[:student_quiz].each do |q,a|
      
      ques=Question.find(q)
      temp_explanation[ques.id] = {}
      
      if ques.question_type.upcase != "DRAG"
        ques.answers.each do |answer|
          temp_explanation[ques.id][answer.id] = answer.explanation
        end
      else
        exp = []
        drag_origin_answer =  ques.answers[0].content.clone
        a.each do |drag|
          exp.append(ques.answers[0].explanation[drag_origin_answer.index(drag)])
        end
        temp_explanation[ques.id][ques.answers[0].id]=exp
        
      end
      
      if ques.question_type != 'header'
        current_user.quiz_grades.where(:question_id => ques.id, :quiz_id => params[:id]).destroy_all
        current_user.free_answers.where(:question_id => ques.id, :quiz_id => params[:id]).destroy_all
        correct=ques.answers.where(:correct => true).pluck(:id)

        if ques.question_type=="MCQ"
          #{"1":false,"2":true} is converted to [2]
          chosen_correct=a.keys.map{|f| f.to_i}.select{|v| a["#{v}"]==true}.sort
          if params[:commit]=="submit" and chosen_correct.empty?
             return_value=I18n.t("controller_msg.unanswered_questions")
             raise ActiveRecord::Rollback
          end
          if chosen_correct == correct
            temp_explanation[ques.id].each{|ans,expl| explanation[ans]=expl} #if answer is correct show explanations for every answer
          elsif @quiz.show_explanation
            chosen_correct.each{|answer| explanation[answer]= temp_explanation[ques.id][answer]}#add explanation for selected answers only
          end
        elsif ques.question_type=="OCQ"
          chosen_correct=[a.to_i] if !a.blank?
          if params[:commit]=="submit" and a.blank?
            return_value=I18n.t("controller_msg.unanswered_questions")
            raise ActiveRecord::Rollback
          end
          if chosen_correct == correct
            temp_explanation[ques.id].each{|ans,expl| explanation[ans]=expl} #if answer is correct show explanations for every answer
          elsif @quiz.show_explanation
            chosen_correct.each{|answer| explanation[answer]= temp_explanation[ques.id][answer]} #add explanation for selected answers only
          end
          a={a => true} if !a.blank?
        elsif ques.question_type.upcase=="DRAG"
          chosen_correct=a
          correct=ques.answers[0].content
          explanation[ques.answers[0].id]= temp_explanation[ques.id][ques.answers[0].id] if correct == chosen_correct #only show explanation if answer is correct

        elsif ques.question_type=="Free Text Question"
          if params[:commit]=="submit" and a.blank?
            return_value=I18n.t("controller_msg.unanswered_questions")
            raise ActiveRecord::Rollback
          end
          explanation[ques.answers[0].id]= ques.answers[0].explanation if a == ques.answers[0].content #only show explanation if answer is correct
        end

        if !a.nil? and ["OCQ","MCQ"].include?ques.question_type.upcase
          correct_ans[ques.id] = (correct==chosen_correct)? 1:0
          a.each do |k,v|
            if v==true
              current_user.quiz_grades.create(:question_id => ques.id, :quiz_id => params[:id], :answer_id => k, :grade => correct_ans[ques.id])
            end
          end
        elsif ques.question_type == "Free Text Question"
          if @quiz.quiz_type == "survey"
            correct_ans[ques.id] = 0
          elsif ques.answers[0].content ==""
            correct_ans[ques.id] = 0
          else
            match_string = ques.answers[0].content
            if match_string =~ /^\/.*\/$/
              match_string =match_string[1..match_string.length-2]
              regex = Regexp.new match_string
              correct_ans[ques.id] =  !!(a =~ regex)? 3:1
            else
              correct_ans[ques.id] = !!(a.downcase == match_string.downcase)? 3:1
            end
          end
          if a != nil
            current_user.free_answers.create(:question_id => ques.id, :quiz_id => params[:id], :answer => a, :grade => correct_ans[ques.id])
          end
        else #Drag
          correct_ans[ques.id]=(correct==chosen_correct)? 1:0
          current_user.free_answers.create(:question_id => ques.id, :quiz_id => params[:id], :answer => a, :grade => correct_ans[ques.id])
        end
      end
    end

    #finished saving
    @status= current_user.quiz_statuses.where(:quiz_id => params[:id], :course_id => params[:course_id])[0]
    if @status.nil?
      @status=current_user.quiz_statuses.create(:group_id => @quiz.group_id,:quiz_id => params[:id], :course_id => params[:course_id], :status => "Saved")
    end
    #if submit
    if params[:commit]=="submit"
      #if haven't submitted or submitted but still have more retries.
      if @status.status!= "Submitted" || @status.attempts <= @quiz.retries
        @status.update_attributes!(:status => "Submitted", :attempts => @status.attempts + 1)
      else
        return_value=I18n.t("controller_msg.cant_submit_no_more_attempts")
        raise ActiveRecord::Rollback
        #rollback .. can't submit
      end
    else
    #if save
      if @status.status=="Submitted" #can't save if already submitted!
        #rollback
        return_value=I18n.t("controller_msg.cant_save_already_submitted")
        raise ActiveRecord::Rollback
      end
      if @status.attempts <= @quiz.retries
        @status.update_attributes!( :attempts => @status.attempts + 1)
       else
        return_value=I18n.t("controller_msg.cant_submit_no_more_attempts")
        raise ActiveRecord::Rollback
        #rollback .. can't submit
      end

    end
    correct_ans={} if @status.status!="Submitted"
    explanation = {} if @status.status!="Submitted"
    alert_messages=get_alert_messages(@quiz,@status)

    @quiz.current_user=current_user
    if @quiz.is_done
      next_i = @quiz.group.next_item(@quiz.position)
      next_item={}
      if !next_i.nil?
        next_item[:id] = next_i.id
        next_item[:class_name] = next_i.class.name.downcase
        next_item[:group_id] = next_i.group.id
      end
    else
      next_item=nil
    end


    render :json => {:status => @status,:next_item => next_item, :correct => correct_ans,:explanation => explanation, :alert_messages => alert_messages, :notice => [I18n.t("controller_msg.#{@quiz.quiz_type}_successfully_saved")], :done => [item_pos, group_pos, @quiz.is_done]} and return
  end
  #status= current_user.quiz_statuses.where(:quiz_id => params[:id], :course_id => params[:course_id])[0]
  #alert_messages=get_alert_messages(@quiz,status)
  render :json => {:errors => return_value.blank? ? [I18n.t("transaction_rolled_back")]:[return_value]}, :status => 400
  end
 
  def update_grade
    if @quiz.free_answers.find(params[:answer_id]).update_attributes(:grade => params[:grade])
      render :json => {:notice => I18n.t("controller_msg.grade_updated")}
    else
      render :json => {:errors => [I18n.t("controller_msg.grade_update_fail")]}, :status => 400
    end
  end
  
  # def quiz_copy
  # end

  def change_status_angular
   status=params[:status].to_i
   assign= @quiz.assignment_item_statuses.where(:user_id => params[:user_id]).first
   if !assign.nil?
    #0 original
    (status==0)? assign.destroy : assign.update_attributes(:status => status)
   elsif status!=0
     @quiz.assignment_item_statuses<< AssignmentItemStatus.create(:user_id => params[:user_id], :course_id => params[:course_id], :status => status ,  :group_id =>@quiz.group.id , :quiz_id => @quiz.id)
   end
   render :json => {:success => true, :notice => [I18n.t("courses.status_successfully_changed")]}
  end


private

  def quiz_params
    params.require(:quiz).permit(:course_id, :instructions, :name, :questions_attributes, :group_id, :due_date, 
        :appearance_time,:appearance_time_module, :due_date_module, :required_module , :inordered_module,:position, 
        :type, :visible, :required, :retries, :current_user, :inordered, :graded, :graded_module, :quiz_type, :requirements, :exam, :correct_question_count, :show_explanation)
  end
end 