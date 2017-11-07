class GroupsController < ApplicationController
	load_and_authorize_resource
		#  @group is already loaded

	before_action :getCourse
	# # before_action :correct_user
	# # before_action :correct_id
	before_action :set_zone

	def getCourse
		@course= Course.find(params[:course_id])
	end

	def set_zone
		Time.zone= @course.time_zone
	end

	# # Removed to course model correct student && teacher
	# # def correct_user
	# # end

	# # def correct_id
	# # end

	# def index
	# end

	# def show
	# end

	# def new
	# end

	# def update
	# end

	# def destroy
	# end

	# def sort
	# end

	# def hide_invideo_quiz
	# end

	# def hide_student_question
	# end

	# def get_lecture_progress_angular
	# end

	# def finished_lecture_test
	# end

	# def get_all_items_progress_angular
	# end

	# def get_all_items_progress_angular
	# end

	# def get_quizzes_progress_angular
	# end

	# def get_surveys_progress_angular
	# end

	def new_module_angular
		if @course.start_date > Time.zone.now.to_date
			app= @course.start_date.midnight.beginning_of_hour
		else
			app= Time.zone.now.midnight.beginning_of_hour#Time.zone.now.to_date
		end
		due= app + 1.week

		@group = @course.groups.build(:name => "New Module", :appearance_time => app, :due_date => due, :position => @course.groups.size+1) #added to_date so it won't have time.
		## waiting for events table 
		# @group.events << Event.new(:name => "#{@group.name} "+ t('controller_msg.due'), :start_at => due, :end_at => due, :all_day => false, :color => "red", :course_id => @course.id)

		if @group.save
			render json:{group: @group, :notice => ["groups.module_successfully_created"]}
		else
			render json: {:errors => @group.errors}, status: 400
		end
	end

	def get_group_statistics
		# @group = Group.where(:id => params[:id], :course_id => params[:course_id]).includes(:online_quizzes => :online_answers)
		## waiting for online_quizzes table
		@group = Group.where(:id => params[:id], :course_id => params[:course_id])
		if @group.empty?
			render json: {:errors => ["controller_msg.no_such_module"]}, status: 404 and return
		else
			@group=@group.first
			@group['total_time'] = @group.total_time
			@group['total_questions'] = @group.total_questions
			@group['total_quiz_questions'] = @group.total_quiz_questions
			@group['total_survey_questions'] = @group.total_survey_questions
			@group['total_lectures'] = @group.lectures.count
			@group['total_quizzes'] = @group.quizzes.where(:quiz_type => "quiz").count
			@group['total_surveys'] = @group.quizzes.where(:quiz_type => "survey").count
			@group['total_links'] = @group.custom_links.count
			# @group['custom_links'] = @group.custom_links.sort!{|x,y| ( x.group_position and y.group_position ) ? x.group_position <=> y.group_position : ( x.group_position ? -1 : 1 )  }
			render json: @group
		end
	end
	
	# def new_link_angular
	# end

	# def get_lecture_charts_angular
	# end

	# def validate_group_angular
	# end

	# def get_quiz_chart_angular
	# end

	# def get_module_charts_angular
	# end

	# def get_survey_chart_angular
	# end

	# def get_student_statistics_angular
	# end

	# def change_status_angular
	# end

	# def display_quizzes_angular
	# end

	# def display_questions_angular
	# end

	# def get_student_questions
	# end

	# def get_inclass_active_angular
	# end

	# def get_module_data_angular
	# end

	# def module_copy
	# end

	# def get_module_inclass
	# end

	# def get_quiz_charts_inclass
	# end

	# def get_quiz_charts
	# end

	# def get_survey_charts
	# end

	# def get_module_progress
	# end

	# def last_watched
	# end

	# def get_inclass_student_status
	# end

	# def update_all_inclass_sessions
	# end

	# def get_module_summary
	# end

	# def get_online_quiz_summary
	# end

	# def get_discussion_summary
	# end



private
	def group_params
		params.require(:group).permit(:course_id, :description, :name, :appearance_time, :position, :due_date, :graded ,:required )
	end
end
