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
    questions.each do |q|
      q.answers.each do |a|
        explanation[a.id] = a.explanation
      end
    end
    questions.each_with_index do |q, index|
      if !quiz.course.is_teacher(current_user)
        answers[index]=q.answers.select([:id, :question_id, :content,:explanation])
        if q.question_type.upcase=="DRAG"
          exp = []
          answers[index].each do |a|
            drag_origin_answer =  q.answers[0].content.clone
            if quiz.course.is_student(current_user)
              a.content.shuffle!
            end
            a.content.each do |drag|
              exp.append(a.explanation[drag_origin_answer.index(drag)])
            end
          end
          explanation[q.answers[0].id]=exp
        end

        #getting student answers, grades
        grades=current_user.quiz_grades.where(:quiz_id => params[:id], :question_id => q.id).pluck(:answer_id)
        correct1= current_user.quiz_grades.where(:quiz_id => params[:id], :question_id => q.id)[0]
        grades2=current_user.free_answers.where(:quiz_id => params[:id], :question_id => q.id)
        if grades2.empty?
          s_grades[q.id]={}
          if q.question_type=="MCQ"
            grades.each{|a| s_grades[q.id][a]=true }
          else
            s_grades[q.id]=grades[0]
          end
          correct[q.id]=correct1.grade if !correct1.nil?
        else
          if q.question_type.upcase=="DRAG"
            exp=[]
            grades2[0].answer.each do |drag|
              exp.append(q.answers[0].explanation[drag_origin_answer.index(drag)])
            end
            explanation[q.answers[0].id]=exp
          end
          s_grades[q.id]=grades2[0].answer
          correct[q.id]=grades2[0].grade
        end
        if quiz.course.is_student(current_user) || quiz.course.is_guest(current_user)
          if q.question_type.upcase=="DRAG"
            answers[index][0].explanation = []
          else
            answers[index]=q.answers.select([:id, :question_id, :content])
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
        elsif l.required
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
      @alert_messages['due']= [I18n.localize(quiz.due_date, :format => '%d %b'), (Time.zone.now.to_date - quiz.due_date.to_date).to_i, t("controller_msg.#{day2}")]
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
       render json: {quiz: @quiz, :notice => [I18n.t("controller_msg.#{@quiz.quiz_type}_successfully_updated")] }
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
    ## waiting for events table
    # Event.where(:quiz_id => old_quiz.id, :lecture_id => nil).each do |e|
    #   new_event= e.dup
    #   new_event.quiz_id = copy_quiz.id
    #   new_event.course_id = copy_quiz.course_id
    #   new_event.group_id = copy_quiz.group_id
    #   new_event.save(:validate => false)
    # end

    old_quiz.questions.each do |question|
      new_question = question.dup
      new_question.quiz_id = copy_quiz.id
      new_question.save(:validate => false)
      ## waiting for answers table
      # question.answers.each do |answer|
      #   new_answer = answer.dup
      #   new_answer.question_id = new_question.id
      #   new_answer.save(:validate => false)
      # end
    end

    render json:{quiz: copy_quiz, :notice => [I18n.t("controller_msg.#{copy_quiz.quiz_type}_successfully_created")]}
  end


  def validate_quiz_angular
    @quiz= Quiz.find(params[:id])
    params[:quiz].each do |key, value|
      @quiz[key]=value
    end
    
    if @quiz.valid?
      head :ok
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
  
  # def show_question_inclass  #updating a survey question (hidden or not)
  # end
  
  # def show_question_student  #updating a survey question (hidden or not)
  # end
  
  # def create_or_update_survey_responses
  # end
  
  # def hide_responses
  # end
  
  # def hide_response_student
  # end
  
  # def delete_response
  # end
  
  # def make_visible
  # end
  
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
  
  # def save_student_quiz_angular
  # end
  
  # def update_grade
  # end
  
  # def quiz_copy
  # end
  
  # def change_status_angular
  # end
  

private

  def quiz_params
    params.require(:quiz).permit(:course_id, :instructions, :name, :questions_attributes, :group_id, :due_date, 
        :appearance_time,:appearance_time_module, :due_date_module, :required_module , :inordered_module,:position, 
        :type, :visible, :required, :retries, :current_user, :inordered, :graded, :graded_module, :quiz_type, :parent_id, :requirements)
  end
end 