module CanvasCommonCartridge::Components::Attacher
    def attach_custom_link(link,converted_group,converted_course)
        converted_link = convert_custom_link(link)
        converted_group.module_items << converted_link
    end           
    def attach_lecture(lecture,converted_group,converted_course)
        if lecture.online_quizzes.length == 0 
            converted_lecture = convert_lecture_items(lecture)
            converted_group.module_items << converted_lecture
            convert_module_completion_requirements(converted_lecture.identifier,'must_view',converted_group) if lecture.required || lecture.required_module
        else
            attach_video_quizzes(lecture,converted_group,converted_course) 
        end    
       
    end    
    def attach_video_quizzes(lecture,converted_group,converted_course)         
        lecture_surveys = lecture.online_quizzes.where(:quiz_type=>["survey","html_survey"])
        lecture_quizzes = lecture.online_quizzes.where(:quiz_type=>["invideo","html"])
        if lecture_quizzes.length>0
            convert_video_quiz(lecture,lecture_quizzes,converted_group,converted_course)
        end
        if lecture_surveys.length>0
            convert_video_survey(lecture,lecture_surveys,converted_group,converted_course)
        end   
    end  
    def attach_quiz(quiz,converted_group,converted_course)
        converted_quiz = convert_quiz_items(quiz)
        quiz_module_item = create_module_item('Quizzes::Quiz' ,converted_quiz.identifier)
        converted_group.module_items << quiz_module_item
        converted_course.assessments << converted_quiz
        convert_module_completion_requirements(quiz_module_item.identifier,'must_submit',converted_group) if quiz.required || quiz.required_module
    end   
    def attach_video_question(video_quiz,converted_video_quiz,start_time,end_time)
        in_video_question = convert_question(video_quiz,'on_video',start_time,end_time)
        in_video_question.title = extract_inner_html_text(video_quiz.question)
        in_video_question.material = format_in_video_quiz_body(video_quiz,video_quiz.lecture.url,start_time,end_time) 
        converted_video_quiz.items << in_video_question
    end    
    def attach_questions(quiz,converted_quiz)
        quiz.questions.each do |q|
            converted_question = convert_question(q,'stand_alone_quiz',0,0)
            converted_question.title = extract_inner_html_text(q.content)
            converted_quiz.items << converted_question
        end     
    end    
    def attach_converted_video_quiz(converted_video_quiz,converted_group,converted_course)
        in_video_module_item = create_module_item("Quizzes::Quiz",converted_video_quiz.identifier) 
        in_video_module_item.workflow_state = 'active'
        converted_group.module_items << in_video_module_item
        converted_course.assessments<<converted_video_quiz 
    end
end      