module CanvasCommonCartridge::Components::Utils
    def format_in_video_quiz_body(in_video_quiz,lecture_url,start_time,end_time)
        timed_url = format_timed_lecture_url(in_video_quiz.start_time,lecture_url,start_time,end_time)        
        question = in_video_quiz.question
        tmp_question_body = "<p><iframe src='#{timed_url}' width='560' height='314' allowfullscreen='allowfullscreen'></iframe>#{question}</p>"
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
            end_time   = end_time.floor()+10
        end    
        tmp +="?start=#{start_time}&end=#{end_time}&autoplay=0mute=0&enablejsapi=0 "
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
        # OCQ and MCQ of on video quizzes has no text answers
        group_online_quizzes_types = []
        Group.find(group_id).lectures.each do |l|
            group_online_quizzes_types=l.online_quizzes.pluck(:question_type) if l.online_quizzes.length>0
        end    
        has_missing_text = group_online_quizzes_types.length>0 &&  group_online_quizzes_types.include?("OCQ"||"MCQ")? true:false
        return 
    end    
    def set_video_converted_assessment_title(lecture_name,ctr,question_type)            
        video_converted_assessment_title = lecture_name+'-part '+(ctr).to_s
        video_converted_assessment_title += "[MISSING ANSWERS]" if question_type=="OCQ" || question_type=="MCQ"
        return video_converted_assessment_title
    end       
end