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
		Time.zone= @lecture.course.time_zone
	end

	# def index
	# end

	# def show
	# end

	# def new
	# end

	# def update
	# end

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

	# def destroy
	# end

	# def sort #called from module_editor to sort the lectures (by dragging)
	# end

	# def new_lecture_angular #called from course_editor / module editor to add a new lecture
	# end

	# def get_lecture_angular
	# end

	# def get_quiz_list_angular
	# end

	# def new_quiz_angular
	# end

	# def new_marker
	# end

	# def save_answers_angular
	# end

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

	# def get_old_data_angular
	# end

	# def get_html_data_angular
	# end

	# def get_lecture_data_angular
	# end

	# def switch_quiz
	# end

	# def online_quizzes_solved
	# end

	# def validate_lecture_angular
	# end

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

	# def lecture_copy
	# end

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
    params.require(:lecture).permit(:course_id, :description, :name, :url, :group_id, :appearance_time, :due_date, :duration,:aspect_ratio, :slides, :appearance_time_module, :due_date_module,:required_module , :inordered_module, :position, :required, :inordered, :start_time, :end_time, :type )
  end
end