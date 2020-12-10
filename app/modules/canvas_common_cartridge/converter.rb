
module CanvasCommonCartridge::Converter
    include CanvasCommonCartridge::Components::Utils
    include CanvasCommonCartridge::Components::Creator 
    include CanvasCommonCartridge::Components::Attacher 
    include HelperExportCourseAsText
    def convert_groups(group,converted_course,with_export_fbf,current_user)
        converted_group = create_converted_group(group)
        group_items = order_group_items(group)
        group_items.each do |item|
            case item.class.name
            when "Lecture"
                attach_lecture(item,converted_group,converted_course,with_export_fbf,current_user)
            when "Quiz"
                attach_quiz(item,converted_group,converted_course)
            when "CustomLink"
                attach_custom_link(item,converted_group,converted_course)          
            end    
        end    
        return converted_group
    end   
    def convert_lecture_items(lecture)
        converted_lecture = create_converted_lecture(lecture)
        return converted_lecture
    end
    def convert_quiz_items(quiz)
        quiz_type = quiz.quiz_type =="survey"? "survey": "practice_quiz"
        converted_quiz = create_converted_assessment(quiz_type)
        converted_quiz.title = quiz.name
        converted_quiz.title +="[MISSING DRAG AND DROP]" if quiz.questions.pluck(:question_type).include?"drag"
        converted_quiz.unlock_at = quiz.appearance_time
        converted_quiz.due_at = quiz.due_date
        converted_quiz.allowed_attempts = quiz.retries
        attach_questions(quiz,converted_quiz)
        return converted_quiz
    end
    def convert_question(quiz,quizLocation,quiz_slide)
        converted_question_type = map_SL_quiz_type_to_CC_question_type(quiz.question_type,quiz,quizLocation) 
        converted_question = create_converted_question(converted_question_type)
        # converted_question.title = extract_inner_html_text(quizLocation=="stand_alone_quiz"? quiz.content : quiz.question)
        converted_question.material = quizLocation=="stand_alone_quiz"? extract_inner_html_text(quiz.content): format_in_video_quiz_body(quiz,quiz_slide) 
        if converted_question_type != "essay_question" && quizLocation=="stand_alone_quiz"
            quiz.answers.each do |answer| 
                converted_answer = convert_quiz_answer(answer,converted_question)
                converted_question.answers << converted_answer
            end    
        end
        if converted_question_type != "essay_question" && quizLocation=="on_video" 
            quiz.online_answers.each do |answer| 
                converted_answer = convert_quiz_answer(answer,converted_question)
                converted_question.answers << converted_answer
            end    
        end
        return converted_question
    end
    def convert_quiz_answer(answer,converted_question)
        converted_answer = create_converted_answer(answer)
        if answer.correct
            converted_answer.fraction=1.0
        else
            converted_answer.fraction=0.0
        end         
        if converted_question.question_type === 'fill_in_multiple_blanks_question'
            converted_answer.resp_ident = 'answer_'+converted_answer.id.to_s
            converted_question.material += " [#{converted_answer.resp_ident}]"
        end    
        return converted_answer
    end  
    def convert_custom_link(link)
        converted_link = create_converted_link(link)
        return converted_link
    end   

    def convert_video_quiz(lecture,lecture_quizzes,converted_group,converted_course) 
         #download lecture video to extract in video quiz slide
            
        #prior quizzes video
        if lecture_quizzes.first.start_time>2
            attach_interquizzes_video(lecture,lecture.name+" (part 1)",0,lecture_quizzes.first.start_time,converted_group) 
            ctr = 2
        else 
            ctr = 1
        end     
        lecture_quizzes.each_with_index do |on_video_quiz,i|
            converted_video_quiz = create_video_converted_assessment('invideo',set_video_converted_assessment_title(lecture.name,ctr,on_video_quiz),lecture.due_date)
            start_time = on_video_quiz.start_time-5
            end_time = on_video_quiz.start_time+1
            if on_video_quiz.quiz_type=='invideo'
                begin 
                    downloaded_lecture = download_lecture(lecture.url,on_video_quiz.start_time,on_video_quiz.id)
                    quiz_slide = extract_img(downloaded_lecture,on_video_quiz.id,on_video_quiz.start_time) 
                rescue
                    quiz_slide={}
                    quiz_slide[:name] = "slide_quiz_#{on_video_quiz.id}.jpg"
                    quiz_slide[:path] =  "./public/assets/images/question.jpg"
                    converted_video_quiz.title += "[IMAGE FAILED]" 
                end    
                attach_file(quiz_slide,converted_course)
            end
            attach_video_question(on_video_quiz,converted_video_quiz,quiz_slide)
            convert_module_completion_requirements(converted_video_quiz.identifier,'must_view',converted_group) if lecture.required || lecture.required_module
            attach_converted_video_quiz(converted_video_quiz,converted_group,converted_course)
            if on_video_quiz != lecture_quizzes.last
                #inter quizzes video
                attach_interquizzes_video(lecture,lecture.name+' (part '+(ctr+1).to_s+")",end_time,lecture_quizzes[i+1].start_time,converted_group) 
            else    
                #post quizzes video
                attach_interquizzes_video(lecture,lecture.name+' (part '+(ctr+1).to_s+")",lecture_quizzes.last.end_time,lecture.end_time,converted_group) 
            end   
            ctr+=2
        end  
        clear_tmp_video_processing(0)
    end
    def attach_interquizzes_video(lecture,title,start_time,end_time,converted_group)
        converted_video_post_quiz = create_converted_lecture(lecture)
        converted_video_post_quiz.url = format_timed_lecture_url(0,
            converted_video_post_quiz.url,
            start_time,
            end_time
        )
        converted_video_post_quiz.title = title
        converted_group.module_items << converted_video_post_quiz
        convert_module_completion_requirements(converted_video_post_quiz.identifier,'must_view',converted_group) if lecture.required || lecture.required_module
    end    
    def convert_video_survey(lecture,lecture_surveys,converted_group,converted_course)
        #initialization of video survey
        converted_video_survey_title = lecture.name+' survey'
        converted_video_survey_title +='[MISSING ANSWERS]' if has_missing_answer_text_at_lecture_surveys(lecture_surveys)
        converted_video_survey = create_video_converted_assessment('survey',converted_video_survey_title,lecture.due_date)
           
        #setting the video survey body
        lecture_surveys.each do |on_video_survey|
            if on_video_survey.quiz_type == 'survey'
                begin 
                    downloaded_lecture = download_lecture(lecture.url,on_video_survey.start_time,'_s_'+on_video_survey.to_s) 
                    survey_slide = extract_img(downloaded_lecture,on_video_survey.id,on_video_survey.start_time)                   
                rescue
                    survey_slide = {}
                    survey_slide[:name] = "slide_quiz_#{on_video_survey.id}.jpg"
                    survey_slide[:path] =  "./public/assets/images/question.jpg"
                end     
                attach_file(survey_slide,converted_course)   
            end    
            attach_video_question(on_video_survey,converted_video_survey,survey_slide)
            # attach_video_question(on_video_survey,converted_video_survey,0,0)
        end
        clear_tmp_video_processing(0)
        attach_converted_video_quiz(converted_video_survey,converted_group,converted_course)
    end  
    def convert_module_completion_requirements(indentifier,completion_type,converted_group)
        completion_requirement = create_module_completion_requirements(indentifier,completion_type)
        converted_group.completion_requirements << completion_requirement
    end    
    class CanvasCommonCartridge::Converter::Packager 
        include CanvasCommonCartridge::Converter
      
        def pack_to_ccc(course,current_user,with_export_fbf,for_all_courses)
            # UserMailer.course_export_start(current_user, course, I18n.locale).deliver
            p = CanvasCommonCartridge::Converter::Packager.new
            export_log = ExportLog.create(course_id:course.id,status:"in progress") if for_all_courses
            converted_course = p.create_converted_course(course)
            course.groups.each_with_index do |group,i|
                converted_group = p.convert_groups(group,converted_course,with_export_fbf,current_user)
                p.create_module_prerequisite(converted_group,converted_course.canvas_modules.last.identifier) if converted_course.canvas_modules.length>0
                converted_group.workflow_state = 'active'
                converted_group.title +="[MISSING ANSWERS]" if p.has_missing_answers_text_at_group(group.id)
                converted_course.canvas_modules << converted_group
            end  
            dir = Dir.mktmpdir
            puts "dir",dir
            carttridge = CanvasCc::CanvasCC::CartridgeCreator.new(converted_course)
            packaged_course = carttridge.create(dir)   
            
            if for_all_courses
                file_txt_path = write_course(course)
                puts file_txt_path
                UserMailer.imscc_txt_attachment_email(current_user, course, course.name, packaged_course, file_txt_path, I18n.locale )
            else
                UserMailer.imscc_attachment_email(current_user, course, course.name+".imscc",packaged_course,I18n.locale,with_export_fbf).deliver
            end     
           
            clear_tmp_video_processing(1)
            if for_all_courses && File.size(packaged_course)>0
                export_log.update(course_id:course.id,status:"done") 
            else  
                export_log.update(course_id:course.id,status:"failed") 
            end     
        end
        handle_asynchronously :pack_to_ccc, :run_at => Proc.new { 1.seconds.from_now }
    end    
end
