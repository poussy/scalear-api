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

	def update
		@group = @course.groups.find(params[:id])
		if @group.update_attributes(group_params)
			@group.events.where(quiz_id: nil, lecture_id: nil)[0].update_attributes(
				name: "#{@group.name} due", 
				start_at: params[:group][:due_date], 
				end_at: params[:group][:due_date], 
				all_day: false, 
				color: 'red', 
				course_id: @course.id) # its ok since I only have the due date.

			@group.lectures.each do |l|
				l.appearance_time = @group.appearance_time if l.appearance_time_module
				l.due_date = @group.due_date if l.due_date_module
				l.required = @group.required if l.required_module
				l.graded = @group.graded if l.graded_module
				l.save
			end

			@group.quizzes.each do |q|
				q.due_date = @group.due_date if q.due_date_module
				q.required = @group.required if q.required_module
				q.graded = @group.graded if q.graded_module
				q.save
			end
			render json: { notice: [I18n.t('groups.module_successfully_updated')] }
		else
			render json: { errors: @group.errors, appearance_time: @group.appearance_time.strftime('%Y-%m-%d') }, status: :unprocessable_entity
		end
	end

	def destroy
		@group = @course.groups.find(params[:id])

		if @group.destroy
			SharedItem.delete_dependent("modules", params[:id].to_i,current_user.id)
			render json: {:notice => [I18n.t("groups.module_successfully_deleted")]}
		else
			render json: {:errors => [I18n.t("groups.could_not_delete_module")]}, :status => 400
		end
	end

	def sort
		@groups = Group.where(:course_id => @course.id)
		params['group'].each_with_index do |g,index|
			group = @groups.select{|f| f.id==g['id'].to_i}[0] #find(g['id'])
			group.position = index + 1
			group.save
		end
		render json: {:notice => [I18n.t("controller_msg.modules_sorted")]}
	end

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
		@group.events << Event.new(:name => "#{@group.name} "+ I18n.t('controller_msg.due'), :start_at => due, :end_at => due, :all_day => false, :color => "red", :course_id => @course.id)

		if @group.save
			render json:{group: @group, :notice => ["groups.module_successfully_created"]}
		else
			render json: {:errors => @group.errors}, status: 400
		end
	end

	def get_group_statistics
		@group = Group.where(:id => params[:id], :course_id => params[:course_id]).includes(:online_quizzes => :online_answers)
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
	
	def new_link_angular
		@group= Group.find(params[:id])
		position=1
		position= @group.get_items.size+1 if @group.get_items.size > 0
		@link = @group.custom_links.build(:name => "New Link", :url => "Empty", :course_id => params[:course_id], :position => @group.get_items.size+1)
		if @link.save
		render json: {link: @link, :notice => I18n.t("controller_msg.link_successfully_created")}
		else
		render json: {:errors => @link.errors}, status: 400
		end
	end

	# def get_lecture_charts_angular
	# end

	def validate_group_angular
		if params[:group]
			params[:group].each do |key, value|
				@group[key]=value
			end
		end

		if @group.valid?
			render json:{ :nothing => true }
		else
			render json: {errors: @group.errors.full_messages}, status: :unprocessable_entity
		end
  	end

	# def get_quiz_chart_angular
	# end

	# def get_module_charts_angular
	# end

	# def get_survey_chart_angular
	# end

	def get_student_statistics_angular
		@modulechart=Group.where(:id => params[:id], :course_id => params[:course_id]).includes([{:lectures => [:confuseds, :video_events]}]).first
		if @modulechart.nil?
			render json: {:errors => ["controller_msg.no_such_module"]}, status: 404 and return
		end

		@all_stats= @modulechart.get_statistics
		@confused=@all_stats[0]
		@back=@all_stats[1]
		@pause=@all_stats[2]
		@discussion=@all_stats[3]
		@duration=@all_stats[4]
		@time_list=@all_stats[5]
		@lecture_names=@all_stats[6]
		@really_confused=@all_stats[7]
		@first_lecture = @modulechart.lectures.first.url if !@modulechart.lectures.empty?

		@confused_chart= Confused.get_rounded_time_module(@confused) #right now I round up. [[234,5],[238,6]]
		@really_confused_chart= Confused.get_rounded_time_module(@really_confused) #right now I round up. [[234,5],[238,6]]
		@back_chart= VideoEvent.get_rounded_time_module(@back) #right now I round up. [[234,5],[238,6]]
		@pause_chart= VideoEvent.get_rounded_time_module(@pause) #right now I round up. [[234,5],[238,6]]
		## waiting for discussion app
		# @question_chart2= VideoEvent.get_rounded_time_module(@discussion) #right now I round up. [[234,5],[238,6]]
		@question_chart = @question_chart2.to_a.map{|v| v=[v[0],v[1][0]]} #getting the time [time,count]
		@questions_list = @question_chart2.to_a.map{|v| v=[v[0],v[1][1]]} #getting the questions [time,questions]

		@min= Time.zone.parse(Time.seconds_to_time(0)).to_i
		@max= Time.zone.parse(Time.seconds_to_time(@duration)).floor(15.seconds).to_i

		render json: {:confused => @confused_chart, :really_confused => @really_confused_chart, :back => @back_chart, :pauses => @pause_chart, :questions => @question_chart, :question_text => @questions_list, :width => @duration, :time_list => @time_list, :lecture_names => @lecture_names, :lecture_url => @first_lecture, :min => @min, :max => @max}
	end

	def change_status_angular
		status=params[:status].to_i
		assign= @group.assignment_statuses.where(:user_id => params[:user_id]).first
		if !assign.nil? and status==0 #original
			assign.destroy
		elsif !assign.nil? #status anything else
			assign.update_attributes(:status => status)
		elsif status!=0 and assign.nil?
			@group.assignment_statuses<< AssignmentStatus.new(:user_id => params[:user_id], :course_id => params[:course_id], :status => status)
		end
		render :json => {:success => true, :notice => [ I18n.t("courses.status_successfully_changed")]}		
	end

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

	def module_copy
		id = params[:id] || params[:module_id]
		copy_module= Group.find(id).copy_group(@course)
		copy_module.position = @course.groups.size
		copy_module.save(:validate => false)

		all = copy_module.get_items
		all.each do |s|
			s[:class_name]= s.class.name.downcase
		end
		copy_module[:items] = all
		render json:{group: copy_module, :notice => [I18n.t("groups.module_successfully_created")]}
   	end

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
