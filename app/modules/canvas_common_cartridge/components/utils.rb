require 'youtube-dl.rb'
require 'streamio-ffmpeg'
module CanvasCommonCartridge::Components::Utils
    def format_in_video_quiz_body(in_video_quiz,quiz_slide)
        question = in_video_quiz.question
        # '<div><img src="$IMS_CC_FILEBASE$/files/screenshot.png"/><p>why?</p></div>'
        tmp_question_body = "<div><p>#{question}</p></div>"
        tmp_question_body.insert(5,"<img src=$IMS_CC_FILEBASE$/files/#{quiz_slide[:name]}></img>")  if quiz_slide        
        return tmp_question_body
    end   
    def format_timed_lecture_url(in_video_quiz_start_time,lecture_url,start_time,end_time)
        tmp = lecture_url.remove('watch?v=')
        tmp = tmp.gsub(/http/,'https')  if !tmp.include?('https')
        tmp = tmp.gsub(/.com\//,".com\/embed\/")
        if start_time==0 && end_time==0 #case of survey
            start_time = in_video_quiz_start_time.floor()-30
            end_time   = in_video_quiz_start_time.floor()+14
        else     
            start_time = start_time.floor()
            end_time   = end_time.floor()
        end    
        tmp +="?start=#{start_time}&end=#{end_time}&autoplay=0mute=0&enablejsapi=0&rel=0"
        return tmp
    end      
    def map_SL_quiz_type_to_CC_question_type(type,question,quizLocation)       
        case type
        when "OCQ"
            tranformed_question_type="multiple_choice_question"
        when "MCQ" 
            tranformed_question_type="multiple_answers_question"
        when "Free Text Question"
            # free questiton on video or standalone with match
            tranformed_question_type= "fill_in_multiple_blanks_question"
            # free question wo match standalone || # free question wo match on video 
            if ((quizLocation=="stand_alone_quiz")&&(question.answers.length==0||question.answers[0].content=="")) || ((quizLocation=="on_video")&&(question.online_answers[0].answer==""))
                tranformed_question_type= "essay_question"  
            end 
        else 
            tranformed_question_type="essay_question"
        end
        return tranformed_question_type
    end
    def extract_inner_html_text(html)
        innerText =  ActionController::Base.helpers.strip_tags(html)
        return innerText
    end 
    def order_group_items(group)
        group_items = group.lectures + group.custom_links + group.quizzes
        sorted_items = group_items.sort_by{|obj| obj.position}
        return sorted_items
    end    
    def secure_url(url)
        secure_url = !url.include?('https') ? url.gsub(/http/,'https') : url 
        return secure_url
    end  
    def has_missing_answers_text_at_group(group_id)
        # online answers of quizzes of this group have answer = "Answer 1"
        group_online_quizzes_ids = OnlineQuiz.where(:group_id=>group_id).pluck(:id)
        group_online_answers_text = OnlineAnswer.where(:online_quiz_id=>group_online_quizzes_ids).pluck(:answer)
        has_missing_text = group_online_answers_text.uniq.include?("Answer 1"||"Answer 2"||"Answer 3")
        # OCQ and MCQ of on video quizzes has no text answers
        group_online_quizzes_types = []
        Group.find(group_id).lectures.each do |l|
            group_online_quizzes_types+=l.online_quizzes.pluck(:question_type) if l.online_quizzes.length>0
        end    
        has_ocq_or_mcq = group_online_quizzes_types.uniq.include?("OCQ"||"MCQ")? true:false
        return has_missing_text && has_ocq_or_mcq
    end    
    def set_video_converted_assessment_title(lecture_name,ctr,on_video_quiz)            
        video_converted_assessment_title = lecture_name+'-part '+(ctr).to_s
        video_converted_assessment_title += "[MISSING ANSWERS]" if has_missing_answer_at_video_quiz(on_video_quiz)#(on_video_quiz.quiz_type=="invideo") && (on_video_quiz.question_type=="OCQ" || on_video_quiz.question_type=="MCQ") && (on_video_quiz.online_answers.first.answer=="Answer 1")
        video_converted_assessment_title +="[MISSING DRAG-AND-DROP]"if on_video_quiz.question_type=="drag"
        return video_converted_assessment_title
    end       
    def has_missing_answer_text_at_lecture_surveys(lecture_surveys)
       lectures_surveys_answer_if_has_default_value_array =  lecture_surveys.map{|lecture_survey| lecture_survey.online_answers.pluck(:answer).include?("Answer 1"||"Answer 2"||"Answer 3")}
       has_missing_answer_text_at_lecture_surveys = lectures_surveys_answer_if_has_default_value_array.reduce(:&)
       return has_missing_answer_text_at_lecture_surveys
    end    
    def has_missing_answer_at_video_quiz(on_video_quiz)
        if (on_video_quiz.quiz_type=="invideo") && (on_video_quiz.question_type=="OCQ" || on_video_quiz.question_type=="MCQ") &&  on_video_quiz.online_answers.length >0
          return on_video_quiz.online_answers.pluck(:answer).include?("Answer 1"||"Answer 2"||"Answer 3")
        else
          return false
        end     
    end    
    def download_lecture(video_url,video_portion_start,quiz_id)
        download_path = './tmp/video_processing/video/quiz_id_'+quiz_id.to_s+'%(title)s.%(ext)s'
        # "-ss 00:00:01.00 -t 00:00:35.00"
        puts "video download started"
        args = "-ss "+format_time(video_portion_start).to_s+" -t  00:00:05.00"
        downloaded_video = YoutubeDL.download video_url, {
            # format:"bestvideo",
            output:download_path,
            # "recode-video":"mp4",
            "postprocessor-args":args
        }
        puts "video download completed"
        return downloaded_video
    end    
    def extract_img(downloaded_video,quiz_id) 
        lecture_slide = {} 
        Dir.mkdir('./tmp/video_processing/images/') unless Dir.exist?('./tmp/video_processing/images/')
        lecture_slide[:name] = "slide_quiz_#{quiz_id}.jpg"
        lecture_slide[:path] =  "./tmp/video_processing/images/"+lecture_slide[:name]
        extractable_video = transcode_to_mp4(downloaded_video)
        # extractable_video = FFMPEG::Movie.new(downloaded_video._filename)
        extractable_video.screenshot(lecture_slide[:path] , seek_time:1,quality:3)
        return lecture_slide
    end   
    def clear_tmp_video_processing(type)
        FileUtils.rm_rf(Dir['./tmp/video_processing/video/*'])
        if type==1
            FileUtils.rm_rf(Dir['./tmp/video_processing/images/*'])
        end    
    end    
    def format_time(t)
        return  Time.at(t).utc.strftime "%H:%M:%S.%m"
    end    
    def transcode_to_mp4(downloaded_video)
        extractable_video = FFMPEG::Movie.new(downloaded_video._filename)
        downloaded_video_extension = downloaded_video._filename.split('.').last
        if  downloaded_video_extension != 'mp4'
            downloaded_video_new_name = downloaded_video._filename.remove(downloaded_video_extension).concat('mp4')
            extractable_video.transcode(downloaded_video_new_name,{},{})
        end 
        return downloaded_video_new_name
    end 
end

