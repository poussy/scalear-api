
include CanvasCommonCartridge::Components::Utils 
module HelperExportCourseAsText
    def write_course(course)  
        directory_name = "tmp/course"
        Dir.mkdir(directory_name) unless File.exists?(directory_name)
        course_file = File.open("tmp/course/course_file.txt", "w")
        write_html_header(course_file)
        
        # write course content to file along the time
        course_file.puts "<h1>Course: "+course.name+"</h1>"
        write_course_syllabus(course_file,course)
        course.groups.each do |group|
            course_file.puts "<h2 id='module_#{group.id.to_s}' >Module: "+group.name+"</h2>"
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
    def write_course_syllabus(course_file,course)
        course_file.puts "<p>Course Modules</p>"
        course_file.puts "<ul>"
        course.groups.each do |group|
            link = "<li><div onclick='goTo(\"module_#{group.id.to_s}\")' style='text-decoration: underline'>#{group.name}</div></li>" 
            course_file.puts link
        end 
        course_file.puts "</ul>"
    end 
    def write_html_header(course_file)       
        course_file.puts "<html>
        <body>
        <style>
            body {
                margin: 40px;
            }
            .left_indentation{
                margin-left: 20px;
            }
            .double_left_indentation {
                margin-left: 40px;
            }
           
        </style>
        <script>
            function goTo(id){
                console.log(typeof(id))
                var my_element = document.getElementById( id );
                my_element.scrollIntoView({
                behavior: 'smooth',
                block: 'start',
                inline: 'nearest'
                });
            }
        </script>
        "
    end 

    def write_lecture(lecture,course_file)
        write_lecture_title(lecture,course_file)
        write_lecture_on_video_quizzes(lecture,course_file)
        write_lecture_on_video_notes(lecture,course_file)
    end 
    def write_lecture_on_video_notes(lecture,course_file)
        if (lecture.online_markers.length > 0)
            lecture.online_markers.each_with_index do |note,i|
                note_txt  = "<p class='left_indentation'>"+"\u2192".encode('utf-8')+" Note #{i+1}: #{ActionController::Base.helpers.strip_tags(note.title)}</p>"     
                note_txt += "<p class='double_left_indentation'>Time : #{time_format(note.time)}</p>"
                note_txt += "<p class='double_left_indentation'>Text : #{ActionController::Base.helpers.strip_tags(note.annotation)}</p>"     
                course_file.puts note_txt
            end 
           
        end
    end 
    def write_lecture_title(lecture,course_file)
        course_file.puts "<div class='left_indentation'><h3>Lecture: "+lecture.name+"</h3>"
        course_file.puts "<p>URL: "+lecture.url+"</p>"
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
        course_file.puts "</div>"
    end
    def write_online_quiz_answer_explanation(a,i,course_file)
        explanation_tmp = get_explanation(a.explanation)
        explanation     = "<p class='left_indentation'>Explanation "+i+": "+explanation_tmp+"</p>"
        course_file.puts explanation if explanation_tmp!=''
    end 
    def write_online_quiz_answer(quiz,a,i,course_file)
        answer_tmp = get_answer(quiz,a)
        answer = "<p class='left_indentation'>Answer "+i+": "
        answer+= "[CORRECT] " if a.correct
        answer+= answer_tmp
        course_file.puts answer+"</p>"
    end  
    def write_online_quiz_question(quiz,i,course_file)
        innerText   =  ActionController::Base.helpers.strip_tags(quiz.question)
        quiz_string = "<p>   "+"\u2192".encode('utf-8')+" Question "+(i+1).to_s+": "+innerText+"</p>"
        course_file.puts  quiz_string
        quiz_type   = "<p class='left_indentation'>Type: "+map_abrv_to_plain(quiz.question_type)+"</p>"
        course_file.puts  quiz_type
        quiz_time   = "<p class='left_indentation'>Time: "+time_format(quiz.time)+"</p>"
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
        course_file.puts "\u21b3".encode('utf-8')+" <h5>"+quiz.name+"</h5>"
        quiz.questions.each do |question|
            write_quiz_question(question,course_file)
            write_quiz_question_answers_and_explanation(question,course_file)
        end 
       
    end 
    def write_quiz_question(question,course_file)
        question_text = "<p>  "+ActionController::Base.helpers.strip_tags(question.content)+"</p>"
        course_file.puts question_text
    end 
    def write_quiz_question_answers_and_explanation(question,course_file)
        question.answers.each_with_index do |answer,i|
            index = (i+1).to_s
            if (question.question_type == "Free Text Question")
                if answer.content == ""
                    answer_row  = "<p class='left_indentation'>Answer "+index+": "+ActionController::Base.helpers.strip_tags(answer.explanation)+"</p>"
                else
                    answer_row  = "<p class='left_indentation'>Answer "+index+": "+answer.content+"\n"
                    answer_row += "<p class='left_indentation'>Explanation "+index+": "+ActionController::Base.helpers.strip_tags(answer.explanation)+" )"+"</p>" if answer.explanation!=""
                end 
            elsif  (question.question_type == "drag")
                answer_row  = "<p class='left_indentation'>Answer "+index+": "+ActionController::Base.helpers.strip_tags( answer.content.join(" "))+"</p>"
                answer_row += "<p class='left_indentation'>Explanation "+index+": "+ActionController::Base.helpers.strip_tags(answer.explanation.join(" "))+"</p>" if answer.explanation.length>0
            else           
                answer_row  = "<p class='left_indentation'>Answer "+index
                answer_row += "[CORRECT]"  if answer.correct
                answer_row += ": "+ActionController::Base.helpers.strip_tags(answer.content)+"</p>"
                answer_row += "<p class='left_indentation'>Explanation "+index+": "+ActionController::Base.helpers.strip_tags(answer.explanation)+"</p>" if answer.explanation!=""          
            end 
            course_file.puts answer_row
        end 
    end
    def write_custom_link(link,course_file)
        course_file.puts "<div class='left_indentation'> <h3>Link: "+link.name+"</h3>"
        course_file.puts "<p>   URL: "+link.url+"</p></div>"
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