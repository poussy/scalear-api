class GroupsController < ApplicationController
	load_and_authorize_resource
		#  @group is already loaded

	# # before_actions :getCourse
	# # before_actions :correct_user
	# # before_actions :correct_id
	before_actions :set_zone

	def set_zone
		Time.zone= @group.course.time_zone
	end
	#
	# # def getCourse
	# # end

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

	# def new_module_angular
	# end

	# def get_group_statistics
	# end

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
		params.require(:group).permit(:course_id, :description, :name, :appearance_time, :position, :due_date, :graded ,:required)
	end
end
