module CanvasCommonCartridge::CcExporter
    include CanvasCommonCartridge::Components::Creator 
    include CanvasCommonCartridge::Components::Attacher
    include CanvasCommonCartridge::Components::Utils

    def pack_to_ccc(course)
        converted_course = create_converted_course(course)
        course.groups.each_with_index do |group|
            converted_group = convert_groups(group,converted_course)
            create_module_prerequisite(converted_group,converted_course.canvas_modules.last.identifier) if converted_course.canvas_modules.length>0
            converted_course.canvas_modules << converted_group
        end 
        dir = Dir.mktmpdir
        carttridge = CanvasCc::CanvasCC::CartridgeCreator.new(converted_course)
        path = carttridge.create(dir)
        return path   
    end

    def convert_groups(group,converted_course)
        converted_group = create_converted_group(group)
        group_items = order_group_items(group)
        group_items.each do |item|
            case item.class.name
            when "Lecture"
                attach_lecture(item,converted_group,converted_course)
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
        converted_quiz.unlock_at = quiz.appearance_time
        converted_quiz.due_at = quiz.due_date
        converted_quiz.allowed_attempts = quiz.retries
        attach_questions(quiz,converted_quiz)
        return converted_quiz
    end
    def convert_question(quiz,quizLocation)
        converted_question_type = map_SL_quiz_type_to_CC_question_type(quiz.question_type,quiz,quizLocation) 
        converted_question = create_converted_question(converted_question_type)
        converted_question.material = quizLocation=="stand_alone_quiz"? extract_inner_html_text(quiz.content): format_in_video_quiz_body(quiz,quiz.lecture.url)
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
            converted_answer.resp_ident = 'answer'+converted_answer.id.to_s
            converted_question.material += " [#{converted_answer.resp_ident}]"
        end    
        return converted_answer
    end  
    def convert_custom_link(link)
        converted_link = create_converted_link(link)
        return converted_link
    end   
    def convert_video_quiz(lecture,lecture_quizzes,converted_group,converted_course)
        converted_video_quiz = create_video_converted_assessment('invideo',lecture.name)
        converted_video_quiz.due_at =  lecture.due_date
        lecture_quizzes.each do |on_video_quiz|
            attach_video_question(on_video_quiz,converted_video_quiz)
        end  
        attach_converted_video_quiz(converted_video_quiz,converted_group,converted_course)
    end
    def convert_video_survey(lecture,lecture_surveys,converted_group,converted_course)
        converted_video_survey = create_video_converted_assessment('survey',lecture.name)
        converted_video_survey.due_at =  lecture.due_date
        lecture_surveys.each do |on_video_survey|
            attach_video_question(on_video_survey,converted_video_survey)
        end
        attach_converted_video_quiz(converted_video_survey,converted_group,converted_course)
    end  
    def convert_module_completion_requirements(indentifier,completion_type,converted_group)
        completion_requirement = create_module_completion_requirements(indentifier,completion_type)
        converted_group.completion_requirements << completion_requirement
    end    
      
end