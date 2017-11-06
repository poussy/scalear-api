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
        render json: {:errors => [t("controller_msg.no_such_quiz")]}, :status => 404
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
          puts "a.content issssss #{exp}"
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
      ### waiting for events table
      #  @quiz.events.where(:lecture_id => nil, :group_id => group.id).destroy_all
      #  if @quiz.due_date.to_formatted_s(:long) != group.due_date.to_formatted_s(:long)
      #      @quiz.events << Event.new(:name => "#{@quiz.name} "+t('controller_msg.due'), :start_at => params[:quiz][:due_date], :end_at => params[:quiz][:due_date], :all_day => false, :color => "red", :course_id => @course.id, :group_id => group.id)
      #  end
       render json: {quiz: @quiz, :notice => [I18n.t("controller_msg.#{@quiz.quiz_type}_successfully_updated")] }
    else
      render json: {:errors => @quiz.errors , :appearance_time =>@quiz.appearance_time.strftime('%Y-%m-%d') }, :status => :unprocessable_entity
    end
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


private

  def quiz_params
    params.require(:quiz).permit(:course_id, :instructions, :name, :questions_attributes, :group_id, :due_date, :appearance_time,:appearance_time_module, :due_date_module, :required_module , :inordered_module,:position, :type, :visible, :required, :retries, :current_user, :inordered)
  end
end
