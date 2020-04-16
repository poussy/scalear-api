module CanvasCommonCartridge::Components::Creator
    
    def create_module_prerequisite(converted_group,prev_module_identifier)
        module_pre_requisite = CanvasCc::CanvasCC::Models::ModulePrerequisite.new
        module_pre_requisite.identifierref = prev_module_identifier
        module_pre_requisite.title = 'in order'
        module_pre_requisite.type ='context_module'
        converted_group.prerequisites << module_pre_requisite
    end    
    def create_module_completion_requirements(identifierref,type)
        completion_requirement = CanvasCc::CanvasCC::Models::ModuleCompletionRequirement.new
        completion_requirement.identifierref=identifierref
        completion_requirement.type=type
        return completion_requirement
    end    
    def create_converted_course(course)
        converted_course = CanvasCc::CanvasCC::Models::Course.new
        converted_course.title = course.name
        converted_course.grading_standards = []
        converted_course.identifier = course.id.to_s
        converted_course.start_at = course.start_date
        converted_course.conclude_at = course.end_date
        converted_course.is_public = Course.last.course_domains.length == 0? true:false 
        converted_course.hide_final_grade = true
        return converted_course
    end   
    def create_converted_group(group)
        converted_group = CanvasCc::CanvasCC::Models::CanvasModule.new
        converted_group.title = group.name
        converted_group.identifier = CanvasCc::CC::CCHelper.create_key(converted_group)
        converted_group.unlock_at = group.appearance_time
        return converted_group
    end   
    def create_module_item(content_type,identifier_to_refer_to)
        module_item = CanvasCc::CanvasCC::Models::ModuleItem.new
        module_item.content_type = content_type
        module_item.title = 'in_video_module_item'      
        module_item.identifier = CanvasCc::CC::CCHelper.create_key(module_item)   
        module_item.identifierref = identifier_to_refer_to
        module_item.workflow_state = 'active'
        return module_item
    end   
    def create_converted_lecture(lecture)
        converted_lecture=CanvasCc::CanvasCC::Models::ModuleItem.new
        converted_lecture.identifier = CanvasCc::CC::CCHelper.create_key(converted_lecture)
        converted_lecture.title = lecture.name
        converted_lecture.url = secure_url(lecture.url)
        converted_lecture.content_type = "ExternalUrl"
        return converted_lecture
    end   
    def create_converted_link(link)
        converted_link=CanvasCc::CanvasCC::Models::ModuleItem.new
        converted_link.identifier = CanvasCc::CC::CCHelper.create_key(converted_link)
        converted_link.title = link.name 
        converted_link.url = secure_url(link.url)
        converted_link.content_type = "ExternalUrl"
        return converted_link
    end    
    def create_converted_assessment(quiz_type) #quiz_src could be lecture or stand-alone quiz
        assessment=CanvasCc::CanvasCC::Models::Assessment.new
        assessment.quiz_type = quiz_type
        assessment.items = []
        assessment.identifier = CanvasCc::CC::CCHelper.create_key(assessment)
        assessment.workflow_state = 'active'
        return assessment 
    end
    def create_video_converted_assessment(quiz_type,title,due_at)
        case quiz_type
        when "invideo","html"
        assessment_type = "practice_quiz"
        # title= "#"        
        when "survey"    
        assessment_type = "survey"
        # title=" surveys"
        end
        converted_video_quiz= create_converted_assessment(assessment_type)
        converted_video_quiz.title= title
        converted_video_quiz.due_at = due_at
        return converted_video_quiz      
    end   
    def create_converted_question(converted_question_type)
        converted_question = CanvasCc::CanvasCC::Models::Question.create(converted_question_type)
        converted_question.identifier = CanvasCc::CC::CCHelper.create_key(converted_question)
        return converted_question
    end    
    def create_converted_answer(answer)
        converted_answer = CanvasCc::CanvasCC::Models::Answer.new
        converted_answer.id = CanvasCc::CC::CCHelper.create_key(converted_answer)
        if defined?(answer.content)
            answer_content = answer.content
        else
        if defined?(answer.answer)
            answer_content = answer.answer
        else  
            answer_content =""
        end 
        end    
        converted_answer.answer_text = extract_inner_html_text(answer_content) 
        converted_answer.feedback = extract_inner_html_text(answer.explanation) if answer.explanation
        return converted_answer
    end  
end

