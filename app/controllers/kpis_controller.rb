class KpisController < ApplicationController

	before_action :init_tempodb ,:authorize

	def authorize
    if !current_user.is_administrator?  and !current_user.is_school_administrator?
      render json: {:errors => [ t("controller_msg.you_are_not_authorized") ]}, status: 403
    end
  end

  def init_tempodb
    # api_key    = ENV['TEMPODB_API_KEY']
    # api_secret = ENV['TEMPODB_API_SECRET']
    # api_host   = ENV['TEMPODB_API_HOST']
    # api_port = Integer(ENV['TEMPODB_API_PORT'])
    # api_secure = ENV['TEMPODB_API_SECURE'] == "False" ? false : true
    username    = ENV['INFLUXDB_USER']
    password = ENV['INFLUXDB_PASSWORD']
    database = ENV['INFLUXDB_DATABASE']
    host   = ENV['INFLUXDB_HOST']
    port = Integer(ENV['INFLUXDB_PORT'])

    @client  =  InfluxDB::Client.new database, :username => username, :password => password, :host => host, :port => port, :time_precision => 's', :retry => -1
    # @client  = TempoDB::Client.new( api_key, api_secret, api_host, api_port, api_secure )
    @series = ["Registration",
               "Login",
               "Lecture_Views",
               "Questions_Asked",
               "Confused",
               "Courses_Created",
               "Lectures_Created",
               "Video_Quizzes_Created",
               "Normal_Quizzes_Created",
               "Surveys_Created",
               "Video_Quizzes_Solved",
               "Normal_Quizzes_Solved",
               "Surveys_Solved",
               "Total_Courses",
               "Total_Students",
               "Total_Teachers",
               "Total_Lectures",
               "Total_Quizzes",
               "Total_Surveys",
               "Total_Questions_Asked",
               "Total_Confused"
             ]
  end

  def init_series
    @series.each do |s|
      @client.create_series(s)
    end
    render json: {}
  end

  def destroy_series
    @series.each do |s|
      @client.delete_series({key: s})
    end
    render json: {}
  end

  def kpi_job
    retrive_date = Date.yesterday

    statistics = get_statistics(retrive_date.to_s)
    @series = @series.map { |s| s.to_sym }
    @series.each do |key|
      # data = [TempoDB::DataPoint.new(retrive_date + 1.day - 1.second, statistics[key])]
      data= {:time => (retrive_date + 1.day - 1.second).to_i, :value => statistics[key]}
      #@client.write_key(key.to_s,data)
      @client.write_point(key.to_s,data)
    end
    #render json: {}
  end

  def init_data
    start_date = Date.new(params[:year].to_i,params[:month].to_i,params[:day].to_i)
    end_date = Date.yesterday
    day_count = (end_date - start_date ).to_i
    totals={}
    formated_data = {}
    for i in 0..day_count
      retrive_date = Date.new(params[:year].to_i,params[:month].to_i,params[:day].to_i)+i.days
      puts retrive_date
      statistics = get_statistics(retrive_date.to_s)
      new_totals = get_totals_per_day(retrive_date.to_s)
      @series.each do |key|
        if(key.include?('Total'))
          if(!totals[key.to_sym])
            totals[key.to_sym] = 0
          end
          totals[key.to_sym] += new_totals[key.to_sym]
          data = totals[key.to_sym]
        else
          data = statistics[key.to_sym]
        end
        if(!formated_data[key.to_sym])
          formated_data[key.to_sym] = [TempoDB::DataPoint.new(retrive_date + 1.day - 1.second, data)]
        else
          formated_data[key.to_sym] << TempoDB::DataPoint.new(retrive_date + 1.day - 1.second, data)
        end
      end
      p statistics
      puts "----"
    end
     # p formated_data
     #    puts "****"
    formated_data.each do |key,data|
      @client.write_key(key.to_s,formated_data[key.to_sym])
    end
   render json: {}
  end

  def read_data
    keys = params[:key]
    start_date = params[:start]
    end_date = params[:end]
    #start_date = DateTime.parse(params[:start])
    end_date = DateTime.parse(params[:end]).strftime('%Y-%m-%d %H:%M:%S')
    #render json: @client.read(start_date, end_date, :keys => keys)[0]
    query_string = "select value from "+keys+" where time > '"+start_date+"' and time < '"+end_date+"' order asc"
    series =  @client.query query_string
    render json: {:data => series[keys]}#
  end

  def read_totals
    render json: get_totals(params[:school])
  end

	def read_totals_for_duration
		render json: Course.school_admin_statistics_course_ids(params[:start_date],params[:end_date], params[:domain], current_user)
	end

	def get_report_data_course_duration
		render json: Course.school_admin_statistics_course_data(params[:start_date],params[:end_date], params[:course_ids] )
	end

  def read_series
    render json: {series: @series}
  end

  def export_school_statistics
    Course.export_school_admin(params[:start_date],params[:end_date], params[:domain], current_user)
    render :json => {:notice => ['Statistics will be exported to CSV and sent to your Email']}
  end
  def get_all_youtube_urls
    render json: Lecture.where("url like ? or url like ?","%www.youtu%","%www.y2u%").pluck(:url,:course_id).uniq
  end
    
  def get_all_youtube_data
    urls_courses_ids=JSON.parse(params[:urls_courses_ids]) #[[url, course id],...]
    youtube_video_data = {} # {youtube video id:{email,course,teacher}}
    urls_courses_ids.each do |url_course_id|
      youtube_video_id = url_course_id[0].split("=")[1].split("&")[0]
      youtube_video_course = Course.find(url_course_id[1])
      youtube_video_data[youtube_video_id] = {:email=>youtube_video_course.user.email,:course=>youtube_video_course.short_name,:teacher=>youtube_video_course.user.name}
    end
    render json: youtube_video_data
  end

	private
	
	def get_statistics(retrive_date)
    status=QuizStatus.where('updated_at::text like ?', "%#{retrive_date}%").includes(:quiz)
    statistics = {
        Registration: User.where("created_at::text like ? AND confirmation_token IS NULL", "%#{retrive_date}%" ).count,
        Login: User.where("current_sign_in_at::text like ? OR updated_at::text like ?", "%#{retrive_date}%", "%#{retrive_date}%").count,

        Questions_Asked: Post.get('where', :query => "created_at::text like '%#{retrive_date}%'").size,#LectureQuestion.where("created_at::text like ?", "%#{retrive_date}%" ).count,
        Confused: Confused.where("created_at::text like ?", "%#{retrive_date}%" ).count,

        Courses_Created: Course.where("created_at::text like ?", "%#{retrive_date}%" ).count,
        Lectures_Created: Lecture.where("created_at::text like ?", "%#{retrive_date}%").count,
        Normal_Quizzes_Created: Quiz.where("quiz_type = ? AND created_at::text like ?","quiz" ,"%#{retrive_date}%" ).count,
        Video_Quizzes_Created: OnlineQuiz.where("created_at::text like ?", "%#{retrive_date}%" ).count,
        Surveys_Created: Quiz.where("quiz_type = ? AND created_at::text like ?","survey" ,"%#{retrive_date}%" ).count,

        Normal_Quizzes_Solved: status.select{|v| v.status=="Submitted" and v.quiz.quiz_type=='quiz'}.size,
        Surveys_Solved: status.select{|v| v.status=="Saved" and v.quiz.quiz_type=='survey'}.size,
        Video_Quizzes_Solved: (OnlineQuizGrade.find_by_sql ["SELECT DISTINCT user_id, online_quiz_id FROM online_quiz_grades WHERE created_at::text like ?" , "%#{retrive_date}%"]).count,

        Lecture_Views: LectureView.where("created_at::text like ?", "%#{retrive_date}%").count,
    }

    totals= get_totals
    totals.each do |k,v|
      statistics[k] = v
    end

    return statistics
  end

  def get_totals(school)
    if school
      email = current_user.email
      course_ids = Course.includes([:user,:teachers]).select{|c| c.teachers.map{|e| e.email.split("@")[1]}.include?(email) }.map{|c| c.id}
      totals={
        Total_Courses: course_ids.count,
        Total_Students: Enrollment.find_all_by_course_id(course_ids).map{|v| v.user_id}.uniq.count,
        Total_Teachers: TeacherEnrollment.find_all_by_course_id(course_ids).map{|v| v.user_id}.uniq.count,
        Total_Lectures:  Lecture.find_all_by_course_id(course_ids).count,
        Total_Quizzes:  Quiz.where("quiz_type = 'quiz'").find_all_by_course_id(course_ids).count,
        Total_Surveys:  Quiz.where("quiz_type = 'survey'").find_all_by_course_id(course_ids).count,
        Total_Questions_Asked: Forum::Post.get('count'),#LectureQuestion.all.count,
        Total_Confused: Confused.find_all_by_course_id(course_ids).count,
      }
    else
      totals={
        Total_Courses: Course.all.count,
        Total_Students: User.joins(:roles).where(:roles =>{:name => "user"}).count,
        Total_Teachers: User.joins(:roles).where(:roles =>{:name => "admin"}).count,
        Total_Lectures:  Lecture.all.count,
        Total_Quizzes:  Quiz.where("quiz_type = 'quiz'").count,
        Total_Surveys:  Quiz.where("quiz_type = 'survey'").count,
        Total_Questions_Asked: Forum::Post.get('count'),#LectureQuestion.all.count,
        Total_Confused: Confused.all.count,
        #Total_Active: User.where("updated_at > ?", 10.minutes.ago).count
      }
    end

    return totals
  end

	def get_totals_per_day(retrive_date)
    totals={
      Total_Courses: Course.where("created_at::text like ?", "%#{retrive_date}%" ).count,
      Total_Students: User.joins(:roles).where("users.created_at::text like ? AND confirmation_token IS NULL", "%#{retrive_date}%" ).where(:roles =>{:name => "user"}).count,
      Total_Teachers: User.joins(:roles).where("users.created_at::text like ? AND confirmation_token IS NULL", "%#{retrive_date}%" ).where(:roles =>{:name => "admin"}).count,
      Total_Lectures: Lecture.where("created_at::text like ?", "%#{retrive_date}%").count,
      Total_Quizzes: Quiz.where("quiz_type = ? AND created_at::text like ?","quiz" ,"%#{retrive_date}%" ).count,
      Total_Surveys: Quiz.where("quiz_type = ? AND created_at::text like ?","survey" ,"%#{retrive_date}%" ).count,
      Total_Questions_Asked: Forum::Post.get('where', :query => "created_at::text like '%#{retrive_date}%'").count, #LectureQuestion.where("created_at::text like ?", "%#{retrive_date}%" ).count,
      Total_Confused: Confused.where("created_at::text like ?", "%#{retrive_date}%" ).count,
    }
    return totals
  end
end