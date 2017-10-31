class CoursesController < ApplicationController
	load_and_authorize_resource   
				#  @course is aready loaded  

	# # # before_filter :correct_user, :except => [:index, :new, :create, :enroll_to_course, :course_copy_angular, :get_all_teachers, :current_courses, :send_system_announcement]
	# before_action :importing?, :except => [:index, :new, :create, :enroll_to_course, :course_copy_angular, :get_all_teachers, :current_courses, :send_system_announcement, :get_role]
	# before_action :set_zone , :except => [:index, :new, :create, :enroll_to_course, :course_copy_angular, :get_all_teachers, :current_courses, :send_system_announcement, :get_role]

	def create
		params[:course][:user_id]=current_user.id
		import_from= params[:import]
		@course = Course.new(params[:course])
		@course.add_professor(current_user , params[:email_discussion])
		respond_to do |format|
			if @course.save
				# params[:subdomains].each do |subdomain|
				# 	if subdomain[0] != "All" && subdomain[1]
				# 		@course.course_domains.create(:domain => subdomain[0])
				# 	end
				# end
				if !import_from.blank?
					@course.update_attributes(:importing => true)
					@course.import_course(import_from)
					#Delayed::Job.enqueue @course.import_course(import_from)
					# check user enter Description or Prerequisites
					render json: {course:@course, :notice => ["controller_msg.importing_course_data"], :importing => true}, status: :created
				else
					render json: {course:@course, :notice => ['controller_msg.course_successfully_created'], :importing => false}, status: :created
				end
			else
				@import=current_user.subjects
				render json: {errors: @course.errors}, status: :unprocessable_entity 
			end
		end
	end

	# # Removed to course model for cancancan
	# # def correct_user
	# # end  

	def set_zone
		Time.zone= @course.time_zone
	end

	# def importing?
	# end  

	# def index
	# end  

	# def current_courses
	# end  

	# def get_role
	# end  

	# def show
	# end  

	# def teachers
	# end  

	# def get_selected_subdomains
	# end  

	# def set_selected_subdomains
	# end  

	# def update_teacher
	# end  

	# def update_student_duedate_email
	# end  

	# def update_teacher_discussion_email
	# end  

	# def get_student_duedate_email
	# end  

	# def save_teachers
	# end  

	# def delete_teacher
	# end  

	# def get_all_teachers
	# end  

	# def new
	# end  

	# def edit
	# end  

	# def validate_course_angular
	# end  

	# def update
	# end  

	# def destroy
	# end  

	# def remove_student
	# end  

	# def unenroll
	# end  

	# def enrolled_students
	# end  

	# def send_email
	# end  

	# def send_batch_email
	# end  

	# def send_batch_email_through
	# end  

	# def send_email_through
	# end  

	# def send_system_announcement
	# end  

	# def course_editor_angular
	# end  

	# def course_copy_angular
	# end  
	
	# def get_group_items_angular
	# end 
	
	# def get_course_angular
	# end  

	# def module_progress_angular
	# end  

	# def get_total_chart_angular
	# end  

	# def enroll_to_course
	# end  

	# def courseware_angular
	# end  

	# def courseware
	# end  

	# def export_csv
	# end  

	# def export_student_csv
	# end  

	# def export_for_transfer
	# end  

	# def export_modules_progress
	# end  


private

  def course_params
    params.require(:course).permit(:description, :end_date, :name, :prerequisites, :short_name, :start_date, :user_ids, :user_id, :time_zone, :discussion_link, :importing, :image_url ,:disable_registration	)
  end
end
