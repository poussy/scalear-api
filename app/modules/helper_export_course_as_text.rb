
include CanvasCommonCartridge::Components::Utils 
module HelperExportCourseAsText
    def write_course(course)  
        directory_name = "tmp/course"
        Dir.mkdir(directory_name) unless File.exists?(directory_name)
        course_file = File.open("tmp/course/course_file.txt", "w")
        # write course content to file along the time
        course_file.puts course.name
        course_file.puts "------------"
        course.groups.each do |group|
            course_file.puts group.name
            group_items = order_group_items(group)
            group_items.each do |item|
                case item.class.name
                when "Lecture"
                    write_lecture(item,course_file)
                when "Quiz"
                    write_quiz(item,course_file)
                when "CustomLink"
                    write_custom_link(item,course_file)        
                end    
            end 
        end 
        course_file.close
        return course_file
    end 
    def write_lecture(lecture,course_file)
        course_file.puts "\u21b3".encode('utf-8')+" "+lecture.name
        course_file.puts "   "+lecture.url
        write_lecture_on_video_quizzes(lecture,course_file)
    end 
    def write_lecture_on_video_quizzes(lecture,course_file)
        lecture.online_quizzes.each do |quiz|
            innerText =  ActionController::Base.helpers.strip_tags(quiz.question)
            quiz_string = "   "+"\u2192".encode('utf-8')+" "+quiz.time.to_s+" "+innerText
            course_file.puts  quiz_string
            quiz.online_answers.each do |a|
                explanation_text = get_explanation(a.explanation)
                answer = get_answer(quiz,a)
                answer = answer+" ("+explanation_text+")" if explanation_text !=""
                answer+= " \u2713".encode('utf-8') if a.correct
                course_file.puts "      "+answer
            end 
        end 
    end 
    def get_answer(quiz,a)
        if (quiz.question_type== "drag" && quiz.quiz_type== "html")
            answer = ActionController::Base.helpers.strip_tags(a.answer.join(" "))
        else 
            answer = quiz.quiz_type=='html' || quiz.quiz_type=="html_survey" ? ActionController::Base.helpers.strip_tags(a.answer): a.answer   
        end 
        return answer
    end 
    def get_explanation(explanation)
       if explanation.is_a?Array
            explanation_text = explanation.join(" ")
            explanation = explanation_text
       end 
       explanation_text = ActionController::Base.helpers.strip_tags(explanation)
       return explanation_text
    end 
    def write_quiz(quiz,course_file)
        course_file.puts "\u21b3".encode('utf-8')+" "+quiz.name
        quiz.questions.each do |question|
            write_quiz_question(question,course_file)
            write_quiz_question_answers_and_explanation(question,course_file)
        end 
       
    end 
    def write_quiz_question(question,course_file)
        question_text = "   "+"\u2192".encode('utf-8')+" "+ActionController::Base.helpers.strip_tags(question.content)
        course_file.puts question_text
    end 
    def  write_quiz_question_answers_and_explanation(question,course_file)
        question.answers.each do |answer|
            if (question.question_type == "Free Text Question")
                if answer.content == ""
                    answer_row  = "     "+ActionController::Base.helpers.strip_tags(answer.explanation)
                else
                    answer_row  = "     "+answer.content
                    answer_row += " ("+ActionController::Base.helpers.strip_tags(answer.explanation)+" )" if answer.explanation!=""
                end 
            elsif  (question.question_type == "drag")
                answer_row  = "     "+ActionController::Base.helpers.strip_tags( answer.content.join(" "))
                answer_row += " ("+ActionController::Base.helpers.strip_tags(answer.explanation.join(" "))+" )" if answer.explanation.length>0
            else     
                answer_row  = "     "+ActionController::Base.helpers.strip_tags(answer.content)
                answer_row += " ("+ActionController::Base.helpers.strip_tags(answer.explanation)+" )" if answer.explanation!=""
                answer_row += " \u2713".encode('utf-8') if answer.correct
              
            end 
            course_file.puts answer_row
        end 
    end
    def write_custom_link(link,course_file)
        course_file.puts "\u21b3".encode('utf-8')+" "+link.name
        course_file.puts "   "+link.url
    end 

end 