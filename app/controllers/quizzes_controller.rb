class QuizzesController < ApplicationController

  load_and_authorize_resource



  def new_or_edit #called from course_editor / module editor to add a new quiz
    group = Group.find(params[:group])
    items = group.get_items
    position = 1
    if !items.empty?
      position = items.last.position + 1
    end
    if params[:type]=="quiz"
      @quiz = @course.quizzes.build(:name => "New Quiz", :instructions =>  t('groups.choose_correct_answer'), :appearance_time => group.appearance_time+100.years  , :due_date => group.due_date ,:appearance_time_module => false, :due_date_module => true, :required_module => true, :graded_module => true,:group_id => params[:group], :quiz_type =>"quiz", :retries => 0, :position => position , :required=>group.required , :graded=>group.graded)
    else
      @quiz = @course.quizzes.build(:name => "New Survey", :instructions => t('groups.fill_in_survey'), :appearance_time => group.appearance_time+100.years , :due_date => group.due_date ,:appearance_time_module => false, :due_date_module => true, :required_module => true, :graded_module => true,:group_id => params[:group], :quiz_type => "survey", :retries => 0, :position => position , :required=>group.required , :graded=>group.graded)
    end
    @quiz['class_name']='quiz'
    if @quiz.save
      render json: {quiz:@quiz, :notice => [t("controller_msg.#{@quiz.quiz_type}_successfully_created")]}
    else
      render json: {:errors => @quiz.errors}, status: 400
    end
  end



private

  def quiz_params
    params.require(:quiz).permit(:course_id, :instructions, :name, :questions_attributes, :group_id, :due_date, :appearance_time,:appearance_time_module, :due_date_module, :required_module , :inordered_module,:position, :type, :visible, :required, :retries, :current_user, :inordered)
  end
end
