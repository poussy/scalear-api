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
				l.skip_ahead = @group.skip_ahead if l.skip_ahead_module
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

	def hide_invideo_quiz  #updating an online quiz (hidden or not)
		quiz_id= params[:quiz]
		hide = params[:hide]
		if hide
			hidden=I18n.t("hidden")
		else
			hidden=I18n.t("visible")
		end

		to_update=OnlineQuiz.find(quiz_id)

		if to_update.update_attributes(:hide => hide)
			render :json => {:notice => ["#{I18n.t('controller_msg.quiz_is_now')} #{hidden}"]}
		else
			render :json => {:errors => [I18n.t("controller_msg.could_not_update_quiz")]}, :status => 400
		end
	end

	# def hide_student_question
	# end

	# def get_lecture_progress_angular
	# end

	# def finished_lecture_test
	# end

	def get_all_items_progress_angular
		@students=@course.users.select("users.*, LOWER(users.name), LOWER(users.last_name)").order("LOWER(users.last_name)").limit(params[:limit]).offset(params[:offset]).includes([:lecture_views, :online_quiz_grades, :free_online_quiz_grades])
		@mod=Group.where(:id => params[:id], :course_id => params[:course_id]).includes({:lectures => [:free_online_quiz_grades, :online_quiz_grades, {:online_quizzes => :online_answers}]}).first

		@total= @course.users.count

		@matrixLecture={}
		@late_lecture={}
		@solvedCount={}
		@totalCount = {}

		@students.each do |s|
			@matrixLecture[s.id]=s.grades_angular_all_items(@mod)
			s.status={}
			s.assignment_item_statuses.each do |stat|
				if stat.status == 1
					s.status[stat.lecture_id || stat.quiz_id]="Finished on Time"
				elsif stat.status == 2
					s.status[stat.lecture_id || stat.quiz_id]="Not Finished"
				end
			end
		end

		@mods=@mod.get_sub_items.map{|m| m.name}
		render json: {:total => @total, :students => @students.to_json(:methods => [:status, :full_name]), :lecture_names => @mods, :lecture_status => @matrixLecture}
  	end

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

		@group = @course.groups.build(:name => "New Module", :appearance_time => app, :due_date => due, :position => @course.groups.size+1, :skip_ahead => true) #added to_date so it won't have time.
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

	def get_survey_chart_angular
			if params[:survey_id]
						@surveychart=Quiz.where(:id => params[:survey_id].to_i, :course_id => params[:course_id].to_i, :quiz_type => "survey").includes(:questions =>  [:free_answers, {:answers => :quiz_grades}]).first
			else
						@surveychart= Group.find(params[:id]).quizzes.where(:quiz_type => "survey").includes(:questions =>  [:free_answers, {:answers => :quiz_grades}]).first
			end

				students = @surveychart.course.users
				students_ids = students.map(&:id)

				if !@surveychart.nil?
						@all_surveys = Group.find(params[:id]).quizzes.where(:quiz_type => "survey").map {|o| [o.name, o.id, o.visible]}
						if(params[:display_only])
								@survey_data=@surveychart.get_survey_student_display_data_angular(students_ids)
								@survey_free_answers= @surveychart.get_survey_student_display_free_text_angular
						else
								@survey_data=@surveychart.get_survey_data_angular(students_ids)
								@survey_free_answers= @surveychart.get_survey_free_text_angular
						end

						@ordered_survey=[]
						sorted_survey =@surveychart.questions.where("question_type !='header'").sort{|x,y| ( x.position and y.position ) ? x.position <=> y.position : ( x.position ? -1 : 1 )  }
						sorted_survey.each {|e| @ordered_survey<<[e.id,e.question_type] }
						@survey_questions= @surveychart.questions.where("question_type !='header'").map{|obj| {:question => obj.content, :type => obj.question_type}}
						@survey_free_questions = @surveychart.questions.where("question_type = 'Free Text Question'").map{|obj| obj={:id => obj.id, :content => obj.content, :show => obj.show, :student_show => obj.student_show} }
						@numbering= @surveychart.get_numbering
						@survey_free={}
						@survey_free_questions.each_with_index do |q, ind|
								id = q[:id]
								@survey_free[id]={}
								@survey_free[id][:title] = q[:content]
								@survey_free[id][:answers] = @survey_free_answers[id]
								@survey_free[id][:show] = q[:show]
								@survey_free[id][:student_show] = q[:student_show]
						end
				end

				students_count = @course.users.size

				render :json => {:chart_data => @survey_data, :chart_questions => @survey_questions, :all_surveys => @all_surveys, :related =>@numbering, :survey_free => @survey_free, :students_count => students_count, :ordered_survey => @ordered_survey, :survey => @surveychart}
	end
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
		@question_chart2= VideoEvent.get_questions_rounded_time_module(@discussion) #right now I round up. [[234,5],[238,6]]
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

	def get_module_data_angular
		group= Group.where(:id => params[:id], :course_id => params[:course_id])
			.includes(
			:lectures =>
			[{:online_quizzes => [
				:online_quiz_grades,
				:free_online_quiz_grades
			]},
			:confuseds,
			:video_notes,
			:online_markers
			]
		).first

		today = Time.zone.now
		if (group.nil? || group.appearance_time >today) &&  !current_user.is_preview?
			render json: {errors: [I18n.t('controller_msg.no_such_module')]}, :status => 404 and return
		else
			if current_user.is_preview?
				lectures = group.lectures.sort{|x,y| ( x.position and y.position ) ? x.position <=> y.position : ( x.position ? -1 : 1 )  }
			else
				lectures = group.lectures.select{|v| v.appearance_time <= today || v.inclass }.sort{|x,y| ( x.position and y.position ) ? x.position <=> y.position : ( x.position ? -1 : 1 )  }
			end    
			lectures.each do |l|
				l[:user_confused]= l.confuseds.select{|c| c.user_id == current_user.id}#.where(:user_id => current_user.id)
				l.current_user= current_user
				l.online_quizzes.each do |q|
					student_online_grades = q.online_quiz_grades.select{|v| v.user_id == current_user.id}
					student_free_online_grades = q.free_online_quiz_grades.select{|v| v.user_id == current_user.id}
					q[:solved_quiz]= (student_online_grades.size!=0 || student_free_online_grades.size!=0)
					if student_online_grades.first
						q[:reviewed]=student_online_grades.first.review_vote
					elsif student_free_online_grades.first
						q[:reviewed]=student_free_online_grades.first.review_vote
					else
						q[:reviewed]=false
					end
					q[:votes_count] =  q.get_votes
					q[:online_answers] = q.online_answers.select([:id, :online_quiz_id, :answer, :xcoor, :ycoor, :width,:height,:pos, :sub_xcoor, :sub_ycoor])

					if q.quiz_type=="html" && q.question_type.downcase=="drag"
						q[:online_answers_drag] = q[:online_answers][0].answer.shuffle! if !q[:online_answers][0].nil?
					end
					if q.question_type.downcase=="free text question"
						q[:online_answers][0].answer=nil if !q[:online_answers][0].nil?
					end
				end
				l[:posts] = l.posts_public
				l[:lecture_notes] = l.video_notes.select{|n| n.user_id == current_user.id} || []
				l[:title_markers] = l.online_markers.select{|a| a.title != ''} || []
				l[:video_quizzes] = l.online_quizzes || []
				l[:annotations] = l.online_markers.select{|a| a.annotation != ''} || []
			end

			render :json => {:module_lectures => lectures}
		end	
	end

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

	def get_module_inclass
		charts_data ={}
		time=0
		_module=Group.where(:id => params[:id], :course_id => params[:course_id]).includes([:lectures, { :online_quizzes => [:lecture, :online_answers, {:online_quiz_grades => :online_answer}, :free_online_quiz_grades]}, :online_quiz_grades, :online_markers ]).first

		if _module.nil?
			render json: {:errors => ["controller_msg.no_such_module"]}, status: 404 and return
		end
		students = _module.course.users
		students_ids = students.map(&:id)
		lectures={}

		review_question_count = 0
		review_quizzes_count = OnlineQuiz.where(:hide => false, :course_id => params[:course_id], :group_id => params[:id], :inclass => false).count
		inclass_quizzes_count= OnlineQuiz.where(:hide => false, :course_id => params[:course_id], :group_id => params[:id], :inclass => true ).count

		_module.lectures.each do |lec|
			lecture_charts = lec.get_charts_visible(students_ids)
			lecture_questions = lec.get_questions_visible
			lec_quiz_free_answers= lec.get_visible_free_text
			lec_quiz_free_questions = lec.online_quizzes.where(:question_type => 'Free Text Question', :hide => false).map{|obj| obj={:id => obj.id, :question => obj.question, :hide => obj.hide, :start_time =>obj.start_time, :time => obj.time, :end_time =>obj.end_time, :inclass => obj.inclass} }
			lec_markers = lec.online_markers.map{|obj| [obj.time, {:id => obj.id, :title => obj.title, :show => !obj.hide, :type => 'marker'}]}
			lectures[lec.id] = {}
			# if lec.titled_markers.count>0
			lectures[lec.id][:markers] = lec_markers
			# end
			if !lecture_questions.empty?
				lectures[lec.id][:charts] = []
				lectures[lec.id][:inclass] = []
				lecture_questions.each do |id, q|
					if q[:type]!= "Free Text Question"
						quiz_array = [q[:time], {:id => id, :title => q[:title], :type => (q[:quiz_type]=='survey' || q[:quiz_type]=='html_survey')? 'Survey' : 'Quiz', :start_time => q[:start_time], :end_time => q[:end_time], :question => q[:title], :show => !q[:hide]}]
						if !q[:inclass]
							quiz_array[1][:answers]= lecture_charts[id]
							lectures[lec.id][:charts] << quiz_array
						else
							quiz_array[1][:online_answers]= OnlineQuiz.find(id).online_answers
							quiz_array[1][:question_type] = q[:type]
							quiz_array[1][:quiz_type] = q[:quiz_type]
							quiz_array[1][:timers] = OnlineQuiz.where(:id => id).select([:intro, :self, :in_group, :discussion]).first
							quiz_array[1][:available] = {:in_self => quiz_array[1][:timers].self>0, :in_group => quiz_array[1][:timers].in_group>0}
							lectures[lec.id][:inclass] << quiz_array
						end
					end
				end
			end

			if !lec_quiz_free_questions.empty?
				lectures[lec.id][:free_question] = []
				lec_quiz_free_questions.each do |q|
					id = q[:id]
					free_quiz_array = [q[:time], {:title => q[:question], :show => !q[:hide], :id => q[:id], :type => q[:quiz_type]=='survey'? 'Survey' : 'Quiz'}]
					if !q[:inclass]
						free_quiz_array[1][:answers]= lec_quiz_free_answers[id]
						lectures[lec.id][:free_question]<< free_quiz_array
					else
						lectures[lec.id][:inclass] << free_quiz_array
					end
				end
			end

			visible_discussion = Forum::Post.find(:all, :params => {lecture_id: lec.id}).select{|v| v.hide == false}
			review_question_count += visible_discussion.count

			if !visible_discussion.empty?
				visible_discussion.each do |p|
					p.comments = p.visible_comments()
				end
				rounded_questions= Forum::Post.get_rounded_time(visible_discussion) #right now I round up. [[234,5],[238,6]]
				lectures[lec.id][:discussion] = rounded_questions.to_a.map{|v| v=[v[0],v[1][1]] } #getting the time [time,count]
			end

			confused = lec.confuseds.where(:very => false, :hide => false ).order('time ASC').select([:time, :hide])
			really_confused = lec.confuseds.where(:very => true, :hide => false ).order('time ASC').select([:time, :hide])

			lectures[lec.id][:confused] =  Confused.get_rounded_time_lecture(confused) if !confused.empty?
			lectures[lec.id][:really_confused] =  Confused.get_rounded_time_lecture(really_confused) if !really_confused.empty?

			if lectures[lec.id].empty?
				lectures.delete lec.id
			end
		end
		students_count = @course.users.size

		render json: { :lectures => lectures, :students_count => students_count, :review_question_count => review_question_count, :review_video_quiz_count => review_quizzes_count, :inclass_quizzes_count => inclass_quizzes_count}
	end

	def get_quiz_charts_inclass
		_module=Group.where(:id => params[:id], :course_id => params[:course_id]).includes([{ :online_quizzes => [:lecture, :online_answers, {:online_quiz_grades => :online_answer}, :free_online_quiz_grades]}, :online_quiz_grades ]).first

		students = _module.course.users
		students_ids = students.map(&:id)

		if _module.nil?
				render json: {:errors => ["controller_msg.no_such_module"]}, status: 404 and return
		end
		quizzes={}
		review_count ={"survey" => 0, "quiz" => 0}
		_module.quizzes.each do |quiz|

				quizzes[quiz.id] = {}

				quiz_display_data = quiz.get_quiz_display_data_angular(students_ids)
				quiz_free_answers = quiz.get_quiz_display_free_text_angular

				quizzes[quiz.id]['answers']=quiz_display_data if !quiz_display_data.empty?

				questions = quiz.questions.select{|v| v.show == true && v.question_type != 'header'}#.where("show = true AND question_type != 'header'")
				review_count[quiz.quiz_type] += questions.size

				if !questions.empty?
						quizzes[quiz.id]['questions']= questions
						quizzes[quiz.id]['questions'].sort!{|x,y| ( x.position and y.position ) ? x.position <=> y.position : ( x.position ? -1 : 1 )  }
						quizzes[quiz.id]['questions'].map!{|obj| {:question => obj.content, :type => obj.question_type, :id => obj.id}}
						quiz_free_questions = quiz.questions.select{|v| v.question_type == 'Free Text Question' and v.show==true}.map{|obj| obj={:id => obj.id, :content => obj.content, :show => obj.show} }

						if !quiz_free_questions.empty?
								if quizzes[quiz.id]['answers'].nil?
										quizzes[quiz.id]['answers']={}
								end
								quiz_free_questions.each_with_index do |q, ind|
										id = q[:id]
										quizzes[quiz.id]['answers'][id]={}
										quizzes[quiz.id]['answers'][id][:title] = q[:content]
										quizzes[quiz.id]['answers'][id][:answers] = quiz_free_answers[id]
										quizzes[quiz.id]['answers'][id][:show] = q[:show]
								end
						end
				end

				quiz_free_answers.each do |k,a|
						review_count[quiz.quiz_type] += a.size
				end

				if quizzes[quiz.id].empty?
						quizzes.delete quiz.id
				else
						quizzes[quiz.id]["type"] = quiz.quiz_type
				end
		end

		render :json => {:quizzes => quizzes, :review_quiz_count => review_count["quiz"], :review_survey_count => review_count["survey"] }
	end

	def get_quiz_charts
		charts_data ={}
		_module=Group.where(:id => params[:id], :course_id => params[:course_id]).includes({:quizzes => [{:questions => [:free_answers, {:answers => :quiz_grades}]}, :quiz_statuses]}).first

		if _module.nil?
			render json: {:errors => ["controller_msg.no_such_module"]}, status: 404 and return
		end

		non_guest_students = _module.course.users.map(&:id)

		quizzes={}
		review_quiz_count = 0

		_module.quizzes.select{|q| q.quiz_type == "quiz"}.each do |quiz|

			submitted_students = quiz.quiz_statuses.select{|qs| qs.status == "Submitted"}.map(&:user_id)
			students = submitted_students & non_guest_students #intersection

			quizzes[quiz.id] = {:meta => quiz}
			chart_questions={}
			questions= quiz.questions.select{|q| q.question_type !='header'}#.where("question_type !='header'")
			quizzes[quiz.id][:questions]= questions.map{|obj| {:question => obj.content, :type => obj.question_type, :id => obj.id, :show => obj.show}}
			review_quiz_count += questions.select{|q| q.show }.size
			# quiz_free_questions = #.where("question_type = 'Free Text Question'")#.map{|obj| obj={:id => obj.id, :content => obj.content, :show => obj.show} }
			# quiz_free_answers= quiz.get_quiz_free_text_angular(students)

			quizzes[quiz.id][:free_question]={}
			questions.select{|q| q.question_type == 'Free Text Question'}.each_with_index do |q, ind|
				id = q[:id]
				answers = q.free_answers.select{|a| students.include?(a.user_id)}
				quizzes[quiz.id][:free_question][id]={:title => q[:content], :answers => answers, :show => q[:show]}
			end

			chart_data={}   #only count those that submitted their answers
			questions.select{|v| v.question_type!="Free Text Question"}.each do |question|
			chart_data[question.id]={:answers =>{}}
			if question.question_type.downcase!="drag"
				question.answers.each do |answer|
					chart_data[question.id][:answers][answer.id]=[0,answer.correct,answer.content]
					chart_data[question.id][:answers][answer.id][0]= answer.quiz_grades.select{|v| students.include?(v.user_id)}.size
				end
			else  #if drag
				question.answers.first.content.each_with_index do |answer, index|  #if drag
					chart_data[question.id][:answers][answer]=[0,true,"#{answer} "+I18n.t('controller_msg.in_correct_place')]
					chart_data[question.id][:answers][answer][0]=question.free_answers.select{|v| students.include?(v.user_id) && answer == v.answer[index]}.size
				end
			end
			end

			quizzes[quiz.id]["charts"]=Hash[chart_data.sort]
		end
		render json: {:quizzes => quizzes, :review_quiz_count => review_quiz_count}
	end

	def get_survey_charts
		_module=Group.where(:id => params[:id], :course_id => params[:course_id]).includes({:quizzes => [{:questions => [:free_answers, {:answers => :quiz_grades}]}, :quiz_statuses]}).first

		if _module.nil?
			render json: {:errors => ["controller_msg.no_such_module"]}, status: 404 and return
		end
		review_survey_count = 0
		surveys={}
		non_guest_students = _module.course.users.map(&:id)

		_module.quizzes.select{|q| q.quiz_type == "survey"}.each do |survey|
			saved_students = survey.quiz_statuses.select{|qs| qs.status == "Saved"}.map(&:user_id)
			students = saved_students & non_guest_students #intersection

			questions = survey.questions.select{|q| q.question_type !='header'}#.where("question_type !='header'")
			review_survey_count += questions.select{|q| q.show }.size

			chart_data ={}
			questions.select{|v| v.question_type != 'Free Text Question'}.each do |question|
				answers={}
				question.answers.each do |answer|
					answers[answer.id] = [answer.quiz_grades.select{|v| students.include?(v.user_id)}.size, answer.content]
				end
				chart_data[question.id]={}
				chart_data[question.id][:show] = question.show
				chart_data[question.id][:student_show] = question.student_show
				chart_data[question.id][:answers] = answers
				chart_data[question.id][:title] = question.content
			end

			surveys[survey.id] = {
			:meta => survey,
			:charts => chart_data,
			:questions => questions.map{|obj| {:question => obj.content, :type => obj.question_type, :id => obj.id}}
			}

			# survey_free_questions = survey.questions.where("question_type = 'Free Text Question'")#.map{|obj| obj={:id => obj.id, :content => obj.content, :show => obj.show} }
			# survey_free_answers = survey.get_survey_free_text_angular

			surveys[survey.id][:free_question]={}
			questions.select{|q| q.question_type == 'Free Text Question'}.each do |q|
				id = q[:id]
				answers = q.free_answers.select{|v| v.answer != '' && students.include?(v.user_id)}
				surveys[survey.id][:free_question][id]={:title => q[:content], :answers => answers, :show => q[:show]}
			end
		end

		render :json => {:surveys => surveys, :review_survey_count => review_survey_count}
	end

 def get_module_progress

  _module=Group.where(:id => params[:id], :course_id => params[:course_id]).includes([
    {:course => :users},
    {:lectures =>
      {:online_quizzes => [
        {:online_answers => :online_quiz_grades},
        :free_online_quiz_grades,
        :online_quiz_grades
      ]}
    },
    :online_quizzes
  ]).first

  if _module.nil?
    render json: {:errors => ["controller_msg.no_such_module"]}, status: 404 and return
  end
  students = _module.course.users
  students_ids = students.map(&:id)
  lectures={}

  review_question_count = 0
  review_quizzes_count = _module.online_quizzes.select{|q| !q.hide && !q.inclass}.size
  inclass_quizzes_count= _module.online_quizzes.select{|q| !q.hide && q.inclass}.size

  _module.lectures.each do |lec|
    lecture_charts = lec.get_charts_all(students_ids)
    lecture_questions = lec.get_questions
    lecture_chart_checked = lec.get_checked_quizzes
    free_questions_collection = lec.get_free_text_question_and_answers(students_ids)
    # quiz_free_questions = lec.get_free_text_questions
    # quiz_free_answers= lec.get_free_text_answers


    lectures[lec.id] = {:meta => lec, :charts => {}, :free_question => {}}

    lecture_questions.each do |id, q|
      if q[:type]!= "Free Text Question"
        lectures[lec.id][:charts][id]=[q[:time], {
          :title => q[:title],
          :type => q[:type],
          :quiz_type =>(q[:quiz_type]=='survey' || q[:quiz_type]=='html_survey')? 'Survey' : 'Quiz',
          :review => q[:review],
          :hide => lecture_chart_checked[id],
          :id => id,
          :answers => lecture_charts[id]
        }]
        if q[:inclass]
          lectures[lec.id][:charts][id][1][:inclass] = true
          lectures[lec.id][:charts][id][1][:timers] = OnlineQuiz.where(:id => id).select([:intro, :self, :in_group, :discussion]).first
        end
      end
    end

    if !free_questions_collection.empty?
      free_questions_collection.each do |id, q|
        # id = q[:id]
        question = q[:question]
        answer = q[:answer]
        lectures[lec.id][:free_question][id] = [question[:time],{
          :review => question[:review],
          :title => question[:title],
          :answers => answer,
          :show => !question[:hide],
          :id => id,
          :quiz_type => (question[:quiz_type]=='survey' || question[:quiz_type]=='html_survey')? 'Survey' : 'Quiz'
        }]
      end
    end

    stat= lec.get_statistics(students)
    lectures[lec.id]["confused"]= Confused.get_rounded_time_lecture(stat[:confused]) #right now I round up. [[234,5],[238,6]]
    lectures[lec.id]["really_confused"]= Confused.get_rounded_time_lecture(stat[:really_confused]) #right now I round up. [[234,5],[238,6]]
    discussion = Forum::Post.get_rounded_time(stat[:discussion])
    lectures[lec.id]["discussion"] = discussion.to_a.map{|v| v=[v[0],v[1][1]]} #lec.posts_all_teacher
    review_question_count += stat[:discussion].select{|v| v.hide == false}.count
  end
  students_count = students.size
  first_lecture = _module.lectures.first if !_module.lectures.empty?

  render json: { :lectures => lectures, :students_count => students_count, :first_lecture => first_lecture, :review_question_count => review_question_count, :review_video_quiz_count => review_quizzes_count, :inclass_quizzes_count => inclass_quizzes_count}
 end
	# def last_watched
	# end

	def get_inclass_student_status
		json = {:status => 0, :updated => false}
		group = Group.find(params[:id])
		session = group.inclass_session
		if !session.nil?
			json[:status] = session.status
			if (params[:status].to_i == 0 && session.status != 0) || (params[:quiz_id].to_i!=-1 && params[:quiz_id].to_i != session.online_quiz_id)
				q = session.online_quiz
				l = q.lecture
				json[:quiz] ={:time => q.time,:question_title => q.question, :question_type => q.question_type,  :id => q.id, :answers => q.online_answers.select([:id, :answer]) }
				json[:lecture] = {:id =>l.id,:name => l.name}
				json[:updated] = true
			end
		end
		render json: json
	end

	def update_all_inclass_sessions
		Group.find(params[:id]).inclass_sessions.update_all(:status => 0)
		render json: {}
	end


	def get_module_summary
		course = Course.find(params[:course_id])
		if course.is_student(current_user)
			group = Group.find(params[:id])
			data = group.get_module_summary_student(current_user)
		else
			group = Group.includes([:course, :lectures,{:online_quizzes => :online_answers}, {:quizzes => [:quiz_grades, :free_answers]}, :online_quiz_grades, :free_online_quiz_grades, :lecture_views ]).find(params[:id])
			data = group.get_module_summary_teacher
		end
		render :json => {:module =>data }
	end
	
	def get_online_quiz_summary
		group = Group.includes(:course).find(params[:id])
		course = group.course
		data = course.is_student(current_user)? group.get_completion_summary_student(current_user) : group.get_online_quiz_summary_teacher
		render :json => {:module =>data }
	end
	
	def get_discussion_summary
		group = Group.includes(:course).find(params[:id])
		course = group.course
		data = course.is_student(current_user)? group.get_discussion_summary_student(current_user) : group.get_discussion_summary_teacher
		render :json => {:module =>data }
	end



	private
		def group_params
			params.require(:group).permit(:course_id, :description, :name, :appearance_time, :position, :due_date, :graded ,:required )
		end
end
