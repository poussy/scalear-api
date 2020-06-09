
include CanvasCommonCartridge::Components::Utils 
module HelperExportCourseAsText
    def write_course(course)  
        directory_name = "tmp/course"
        Dir.mkdir(directory_name) unless File.exists?(directory_name)
        course_file = File.open("tmp/course/course_file.txt", "w")
        course_file.puts "<html><body>"
        # write course content to file along the time
        course_file.puts "<h1>Course: "+course.name+"</h1>"
        course_file.puts "------------"
        course.groups.each do |group|
            course_file.puts "<h3>Module: "+group.name+"</h3>"
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
            course_file.puts "\n \n"
        end 
        course_file.puts "</body></html>"
        course_file.close
        return course_file
    end 
    def write_lecture(lecture,course_file)
        write_lecture_title(lecture,course_file)
        write_lecture_on_video_quizzes(lecture,course_file)
    end 
    def write_lecture_title(lecture,course_file)
        course_file.puts "----"
        course_file.puts "<h3>Lecture: "+lecture.name+"</h3>"
        course_file.puts "URL: "+lecture.url
        course_file.puts "----"
    end 
    def write_lecture_on_video_quizzes(lecture,course_file)
        lecture.online_quizzes.each_with_index do |quiz,i|
            write_online_quiz_question(quiz,i,course_file)         
            quiz.online_answers.each_with_index do |a,i|
                index = (i+1).to_s
                write_online_quiz_answer(quiz,a,index,course_file)
                write_online_quiz_answer_explanation(a,index,course_file)
            end 
        end 
    end
    def write_online_quiz_answer_explanation(a,i,course_file)
        explanation_tmp = get_explanation(a.explanation)
        explanation     = "Explanation "+i+": "+explanation_tmp
        course_file.puts "      "+explanation
    end 
    def write_online_quiz_answer(quiz,a,i,course_file)
        answer_tmp = get_answer(quiz,a)
        answer = "     Answer "+i+": "
        answer+= "[CORRECT] " if a.correct
        answer+= answer_tmp
        course_file.puts "      "+answer
    end  
    def write_online_quiz_question(quiz,i,course_file)
        innerText   =  ActionController::Base.helpers.strip_tags(quiz.question)
        quiz_string = "   "+"\u2192".encode('utf-8')+" Question "+(i+1).to_s+":"+innerText
        course_file.puts  quiz_string
        quiz_type   = "      Type: "+map_abrv_to_plain(quiz.question_type)
        course_file.puts  quiz_type
        quiz_time   = "      Time: "+time_format(quiz.time)
        course_file.puts  quiz_time 
    end 
    def get_answer(quiz,a)
        if (quiz.question_type== "drag" && quiz.quiz_type== "html")
            answer = ActionController::Base.helpers.strip_tags(a.answer.join(" "))
        else 
            answer = ActionController::Base.helpers.strip_tags(a.answer)
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
    def write_quiz_question_answers_and_explanation(question,course_file)
        question.answers.each_with_index do |answer,i|
            index = (i+1).to_s
            if (question.question_type == "Free Text Question")
                if answer.content == ""
                    answer_row  = "Answer "+index+": "+ActionController::Base.helpers.strip_tags(answer.explanation)
                else
                    answer_row  = "Answer "+index+": "+answer.content+"\n"
                    answer_row += "Explanation "+index+": "+ActionController::Base.helpers.strip_tags(answer.explanation)+" )" if answer.explanation!=""
                end 
            elsif  (question.question_type == "drag")
                answer_row  = "Answer "+index+": "+ActionController::Base.helpers.strip_tags( answer.content.join(" "))+"\n"
                answer_row += "Explanation "+index+": "+ActionController::Base.helpers.strip_tags(answer.explanation.join(" ")) if answer.explanation.length>0
            else           
                answer_row  = "Answer "+index
                answer_row += "[CORRECT]"  if answer.correct
                answer_row += ": "+ActionController::Base.helpers.strip_tags(answer.content)+"\n"
                answer_row += "Explanation "+index+": "+ActionController::Base.helpers.strip_tags(answer.explanation) if answer.explanation!=""          
            end 
            course_file.puts answer_row
        end 
    end
    def write_custom_link(link,course_file)
        course_file.puts "\u21b3".encode('utf-8')+" <h3>Link: "+link.name+"</h3>"
        course_file.puts "   URL: "+link.url
    end 
    def map_abrv_to_plain(question_type)
        case question_type
        when "MCQ"
            return "Multiple Choice Answer"
        when "drag"
            return "Drag and Drop Answer"
        when "OCQ"
            return "Single Choice Answer"    
        when "Free Text Question"
            return "Free Text Answer"
        end        
    end 
    def time_format(t)
        return Time.at(t).utc.strftime("%H:%M:%S")
    end 
end 