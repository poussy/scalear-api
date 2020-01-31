module CcUtils
    def cc_course(course)
        transformed_course = create_transformed_course(course)
        course.groups.each do |group|
            transformed_group = cc_groups(group,transformed_course)
            transformed_course.canvas_modules << transformed_group
        end 
        dir = Dir.mktmpdir
        carttridge = CanvasCc::CanvasCC::CartridgeCreator.new(transformed_course)
        path = carttridge.create(dir)
        return path   
    end
    def cc_groups(group,transformed_course)
        transformed_group = create_transformed_group(group)
        group_items = get_sorted_group_items(group)
        (1..group_items.length).each do |i|
            item = group_items[i]
            case item.class.name
            when "Lecture"
                attach_lecture(item,transformed_group,transformed_course)
            when "Quiz"
                attach_quiz(item,transformed_group,transformed_course)
            when "CustomLink"
                attach_custom_link(item,transformed_group,transformed_course)          
            end    
        end    
        return transformed_group
    end   
    def cc_lecture_items(lecture)
        transformed_lecture = create_transformed_lecture(lecture)
        return transformed_lecture
    end
    def cc_quiz_items(quiz)
        quiz_type = quiz.quiz_type =="survey"? "survey": "practice_quiz"
        transformed_quiz = create_transformed_assessment(quiz_type)
        transformed_quiz.title = quiz.name
        transformed_quiz.due_at = quiz.due_date
        transformed_quiz.allowed_attempts = quiz.retries
        attach_questions(quiz,transformed_quiz)
        return transformed_quiz
    end
    def cc_question(quiz,quizLocation)
        transformed_question_type = map_SL_quiz_type_to_CC_question_type(quiz.question_type,quiz,quizLocation) 
        transformed_question = create_transformed_question(transformed_question_type)
        transformed_question.material = quizLocation=="stand_alone_quiz"? extract_inner_html_text(quiz.content): format_in_video_quiz_body(quiz,quiz.lecture.url)
        if transformed_question_type != "essay_question" && quizLocation=="stand_alone_quiz"
            quiz.answers.each do |answer| 
                transformed_answer = cc_quiz_answer(answer,transformed_question)
                transformed_question.answers << transformed_answer
            end    
        end
        if transformed_question_type != "essay_question" && quizLocation=="on_video" 
            quiz.online_answers.each do |answer| 
                transformed_answer = cc_quiz_answer(answer,transformed_question)
                transformed_question.answers << transformed_answer
            end    
        end
        return transformed_question
    end
    def cc_quiz_answer(answer,transformed_question)
        transformed_answer = create_transformed_answer(answer)
        if answer.correct
            transformed_answer.fraction=1.0
        else
            transformed_answer.fraction=0.0
        end         
        if transformed_question.question_type === 'fill_in_multiple_blanks_question'
            transformed_answer.resp_ident = 'answer'+transformed_answer.id.to_s
            transformed_question.material += " [#{transformed_answer.resp_ident}]"
        end    
        return transformed_answer
    end  
    def cc_custom_link(link)
        transformed_link = create_transformed_link(link)
        return transformed_link
    end   
    def cc_video_quiz(lecture,lecture_quizzes,transformed_group,transformed_course)
        transformed_video_quiz = create_video_transformed_assessment('invideo',lecture.name)
        lecture_quizzes.each do |on_video_quiz|
            attach_video_question(on_video_quiz,transformed_video_quiz)
        end  
        attach_transformed_video_quiz(transformed_video_quiz,transformed_group,transformed_course)
    end
    def cc_video_survey(lecture,lecture_surveys,transformed_group,transformed_course)
        transformed_video_survey = create_video_transformed_assessment('survey',lecture.name)
        lecture_surveys.each do |on_video_survey|
            attach_video_question(on_video_survey,transformed_video_survey)
        end
        attach_transformed_video_quiz(transformed_video_survey,transformed_group,transformed_course)
    end  

    def attach_custom_link(link,transformed_group,transformed_course)
        transformed_link = cc_custom_link(link)
        transformed_group.module_items << transformed_link
    end           
    def attach_lecture(lecture,transformed_group,transformed_course)
        transformed_lecture = cc_lecture_items(lecture)
        transformed_group.module_items << transformed_lecture
        attach_video_quizzes(lecture,transformed_group,transformed_course)
    end    
    def attach_video_quizzes(lecture,transformed_group,transformed_course)         
        lecture_surveys = lecture.online_quizzes.where(:quiz_type=>"survey")
        lecture_quizzes = lecture.online_quizzes.where(:quiz_type=>["invideo","html"])
        if lecture_quizzes.length>0
            cc_video_quiz(lecture,lecture_quizzes,transformed_group,transformed_course)
        end
        if lecture_surveys.length>0
            cc_video_survey(lecture,lecture_surveys,transformed_group,transformed_course)
        end   
    end  
    def attach_quiz(quiz,transformed_group,transformed_course)
        transformed_quiz = cc_quiz_items(quiz)
        quiz_module_item = create_module_item('Quizzes::Quiz' ,transformed_quiz.identifier)
        transformed_group.module_items << quiz_module_item
        transformed_course.assessments << transformed_quiz
    end   
    def attach_video_question(video_quiz,transformed_video_quiz)
        in_video_question = cc_question(video_quiz,'on_video')
        transformed_video_quiz.items << in_video_question
    end    
    def attach_questions(quiz,transformed_quiz)
        quiz.questions.each do |q|
            transformed_question = cc_question(q,'stand_alone_quiz')
            transformed_quiz.items << transformed_question
        end     
    end    
    def attach_transformed_video_quiz(transformed_video_quiz,transformed_group,transformed_course)
        in_video_module_item = create_module_item("Quizzes::Quiz",transformed_video_quiz.identifier) 
        transformed_group.module_items << in_video_module_item
        transformed_course.assessments<<transformed_video_quiz 
    end    

    def create_transformed_course(course)
        transformed_course = CanvasCc::CanvasCC::Models::Course.new
        transformed_course.title = course.name
        transformed_course.grading_standards = []
        transformed_course.identifier = course.id.to_s
        transformed_course.grading_standards=[]
        return transformed_course
    end   
    def create_transformed_group(group)
        transformed_group = CanvasCc::CanvasCC::Models::CanvasModule.new
        transformed_group.title = group.name
        transformed_group.identifier = CanvasCc::CC::CCHelper.create_key(transformed_group)
        return transformed_group
    end   
    def create_module_item(content_type,identifier_to_refer_to)
        module_item = CanvasCc::CanvasCC::Models::ModuleItem.new
        module_item.content_type=content_type
        module_item.title = 'in_video_module_item'      
        module_item.identifier = CanvasCc::CC::CCHelper.create_key(module_item)   
        module_item.identifierref = identifier_to_refer_to
        return module_item
    end   
    def create_transformed_lecture(lecture)
        transformed_lecture=CanvasCc::CanvasCC::Models::ModuleItem.new
        transformed_lecture.identifier = CanvasCc::CC::CCHelper.create_key(transformed_lecture)
        transformed_lecture.title = lecture.name
        transformed_lecture.url = lecture.url
        transformed_lecture.content_type = "ExternalUrl"
        return transformed_lecture
    end   
    def create_transformed_link(link)
        transformed_link=CanvasCc::CanvasCC::Models::ModuleItem.new
        transformed_link.identifier = CanvasCc::CC::CCHelper.create_key(transformed_link)
        transformed_link.title = link.name
        link_url = link.url.gsub(/http/,'https')  if !link.url.include?('https')
        transformed_link.url = link_url
        transformed_link.content_type = "ExternalUrl"
        return transformed_link
    end    
    def create_transformed_assessment(quiz_type) #quiz_src could be lecture or stand-alone quiz
        assessment=CanvasCc::CanvasCC::Models::Assessment.new
        assessment.quiz_type = quiz_type
        assessment.items = []
        assessment.identifier = CanvasCc::CC::CCHelper.create_key(assessment)
        return assessment 
    end
    def create_video_transformed_assessment(quiz_type,lecture_name)
        case quiz_type
        when "invideo","html"
           assessment_type = "practice_quiz"
           title= " video quizzes"          
        when "survey"    
           assessment_type = "survey"
           title=" surveys"
        end
        transformed_video_quiz= create_transformed_assessment(assessment_type)
        transformed_video_quiz.title= lecture_name+title
        return transformed_video_quiz      
    end   
    def create_transformed_question(transformed_question_type)
        transformed_question = CanvasCc::CanvasCC::Models::Question.create(transformed_question_type)
        transformed_question.identifier = CanvasCc::CC::CCHelper.create_key(transformed_question)
        return transformed_question
    end    
    def create_transformed_answer(answer)
        transformed_answer = CanvasCc::CanvasCC::Models::Answer.new
        transformed_answer.id = CanvasCc::CC::CCHelper.create_key(transformed_answer)
        if defined?(answer.content)
            answer_content = answer.content
        else
           if defined?(answer.answer)
              answer_content = answer.answer
           else  
            answer_content =""
           end 
        end    
        transformed_answer.answer_text = extract_inner_html_text(answer_content) 
        transformed_answer.feedback = extract_inner_html_text(answer.explanation) if answer.explanation
        return transformed_answer
    end  

    def format_in_video_quiz_body(in_video_quiz,lecture_url)
        timed_url = format_timed_lecture_url(in_video_quiz,lecture_url)        
        question = in_video_quiz.question
        tmp_question_body = "<p><iframe src='#{timed_url}' width='560' height='314' allowfullscreen='allowfullscreen'></iframe>#{question}</p>"
        return tmp_question_body
    end   
    def format_timed_lecture_url(in_video_quiz,lecture_url)
        tmp = lecture_url.remove('watch?v=')
        tmp = tmp.gsub(/http/,'https')  if !tmp.include?('https')
        tmp = tmp.gsub(/.com\//,".com\/embed\/")
        start_time = in_video_quiz.start_time.floor()
        end_time   = in_video_quiz.start_time.floor()+1
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
            puts "==============================="
            puts question.as_json
            puts "----------------------"
            puts question.answers
            puts "========================"
            if ((quizLocation=="stand_alone_quiz")&&(question.answers!=nil)&&(question.answers[0].content=="")) || ((quizLocation=="on_video")&&(question.online_answers[0].answer==""))
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
    def get_sorted_group_items(group)
        group_items = group.lectures + group.custom_links + group.quizzes
        sorted_items = {} 
        group_items.each do |item|
            sorted_items[item.position] = item
        end    
        return sorted_items
    end        
end



# # # //////////////////////////////////
# transformed_course = CanvasCc::CanvasCC::Models::Course.new
# course = Course.last
# transformed_course.title = 'course 125'
# transformed_course.grading_standards = []
# transformed_course.identifier = CanvasCc::CC::CCHelper.create_key(transformed_course)


# myModule = CanvasCc::CanvasCC::Models::CanvasModule.new
# myModule.title = 'first module 125'
# myModule.identifier = CanvasCc::CC::CCHelper.create_key(myModule)

# assessment = CanvasCc::CanvasCC::Models::Assessment.new
# assessment.quiz_type ='practice_quiz'
# assessment.items=[]
# assessment.title = 'my assessmemnt 125'
# assessment.identifier = CanvasCc::CC::CCHelper.create_key(assessment)

# module_item=CanvasCc::CanvasCC::Models::ModuleItem.new
# module_item.title = 'my assessment 125b'
# module_item.content_type='Quizzes::Quiz'
# module_item.identifierref = assessment.identifier
# module_item.identifier = CanvasCc::CC::CCHelper.create_key(module_item)


# question = CanvasCc::CanvasCC::Models::Question.create('essay_question')
# question.identifier='456'
# question.title='is this a title?'
# question.material = '<p><iframe src="//www.youtube.com/embed/91a3JA6Fan0?start=6&amp;end=10" width="560" height="314" allowfullscreen="allowfullscreen"></iframe>why</p>'

# answer = CanvasCc::CanvasCC::Models::Answer.new()
# answer.id='123'
# answer.feedback='explanation'
# answer.answer_text='question answer'
# page = CanvasCc::CanvasCC::Models::Page.new
# page.identifier = 3
# page.page_name = 'my page name'
# page.body = 'text in page'
# page.workflow_state="active"
# page.title = 'page title'
# question.answers << answer
# assessment.items << question
# module_item.identifierref = assessment.identifier.to_i
# myModule.module_items << module_item
# transformed_course.canvas_modules << myModule
# transformed_course.assessments<<assessment
# transformed_course.pages << page
