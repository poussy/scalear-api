module FeedbackFruit::ExportQuestion
    def export_video_quizzes(quizzes,access_token, activity_video_id, group_id)
        quizzes.each do |quiz|
            export_video_quiz(access_token,activity_video_id, group_id, quiz)
        end   
    end
    def export_video_quiz(access_token,activity_video_id, group_id, quiz)
        question_id = export_question(access_token, activity_video_id, group_id, quiz)
        export_answers(quiz, access_token, question_id)
    end
    def export_question(access_token, activity_video_id, group_id, quiz)
        #create a time fragment 
        fragment_id = get_fragment_id(access_token, activity_video_id, quiz)
        puts "<<<<<<<<<<<<<<fragment_id<<<<<<<<<<"
        puts fragment_id
        puts "<<<<<<<<<<<<<<group_id<<<<<<<<<<<<<"
        puts group_id
        puts "<<<<<<<<<<<<<<access_token<<<<<<<<<"
        puts access_token

        #attach a new annotation 
        annotation_id = get_annotation_id(access_token, fragment_id, group_id)
        puts "<<<<<<<<<<<<<<annotation_id<<<<<<<<<"
        puts annotation_id
        #attach question to the moment --- get question_id
        question_id = get_question_id(access_token, quiz, annotation_id, group_id, activity_video_id)
        #attach pic --- get media_id
        return question_id
    end
    def get_fragment_id(access_token, activity_video_id, quiz)
        query_url =	'https://staging-api.feedbackfruits.com/v1/fragments'
        response = ""

        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "retreiving acess token from feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.post(query_url,
                :headers => { 'Content-Type' => 'application/vnd.api+json','Authorization'=>' Bearer '+access_token } ,
                :body=>'{"data":{"attributes":{"time-min":'+(quiz.start_time-2).to_s+',"time-max":'+(quiz.start_time+2).to_s+'},"relationships":{"activity":{"data":{"type":"videos","id":"'+activity_video_id+'"}}},"type":"video-fragments"}}'
            )
        end	    
        fragment_id=response.parsed_response['data']['id']
       return fragment_id
    end 
    def get_annotation_id(access_token, fragment_id, group_id)
        query_url =	'https://staging-api.feedbackfruits.com/v1/annotations'
        response = ""
        
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "retreiving acess token from feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.post(query_url,
                :headers => { 'Content-Type' => 'application/vnd.api+json','Authorization'=>'Bearer '+access_token } ,
                :body => '{"data":{"attributes":{"required":true},"relationships":{"parent":{"data":{"type":"video-fragments","id":"'+fragment_id+'"}},"group":{"data":{"type":"activity-groups","id":"'+group_id+'"}}},"type":"annotations"}}'
            )
        end	    
        annotation_id = response.parsed_response['data']['id']
        return annotation_id
    end
    def get_question_id(access_token, quiz, annotation_id, group_id, activity_video_id)
        case quiz.question_type
        when "OCQ" || "MCQ"
            question_id = get_cq_question_id(access_token, quiz, annotation_id, group_id, activity_video_id)
        when "Free Text Question"
            question_id = get_free_text_question_id(access_token, quiz, annotation_id, group_id, activity_video_id)
        end    
        return question_id
    end 
    def get_cq_question_id(access_token, quiz, annotation_id, group_id, activity_video_id)
        query_url =	'https://staging-api.feedbackfruits.com/v1/engines/questions/questions'
        response = ""
        
        question_text = Nokogiri::HTML.fragment(quiz.question).text
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "retreiving acess token from feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.post(query_url,
                :headers => { 'Content-Type' => 'application/vnd.api+json','Authorization'=>'Bearer '+access_token } ,
                # :body => '{"data":{"attributes":{"min-choices":null,"max-choices":'+set_max_choices(quiz)+',"body":"'+quiz.question+'","show-peers-answers":true},"relationships":{"annotation":{"data":{"type":"annotations","id":"'+annotation_id+'"}},"group":{"data":{"type":"activity-groups","id":'+group_id+'}},"parent":{"data":{"type":"videos","id":'+activity_video_id+'}}},"type":"multiple-choice-questions"}}'
                :body => '{"data":{"attributes":{"min-choices":null,"max-choices":'+set_max_choices(quiz)+',"body":"'+question_text+'","show-peers-answers":true},"relationships":{"annotation":{"data":{"type":"annotations","id":"'+annotation_id+'"}},"group":{"data":{"type":"activity-groups","id":"'+group_id+'"}},"parent":{"data":{"type":"videos","id":"'+activity_video_id+'"}}},"type":"multiple-choice-questions"}}'
            )
        end	    

        question_id = response.parsed_response['data']['id']
        return question_id
    end   

    def get_free_text_question_id(access_token, quiz, annotation_id, group_id, activity_video_id)
        query_url =	'https://staging-api.feedbackfruits.com/v1/engines/questions/questions'
        response = ""
        question_text = Nokogiri::HTML.fragment(quiz.question).text
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "retreiving acess token from feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.post(query_url,
                :headers => { 'Content-Type' => 'application/vnd.api+json','Authorization'=>'Bearer '+access_token } ,
                :body => '{"data":{"attributes":{"solution":"CORRECT ANSWER, OPTIONAL","body":"'+question_text+'","show-peers-answers":false},"relationships":{"annotation":{"data":{"type":"annotations","id":"'+annotation_id+'"}},"group":{"data":{"type":"activity-groups","id":"'+group_id+'"}},"parent":{"data":{"type":"videos","id":"'+activity_video_id+'"}}},"type":"open-questions"}}'
            )
        end	    
        question_id = response.parsed_response['data']['id']
        puts "<<<<<<<<<<<<<<<<<<<<<get_free_text_question_id question_id"
        puts question_id
        return question_id
    end   
    def set_max_choices(quiz)
        case quiz.question_type
        when "OCQ"
            max_choices = "1"
        when "MCQ"
            max_choices = quiz.online_answers.count.to_s
        #free text or drag and drop    
        else 
            max_choices = "1"
        end 
        return max_choices
    end 
    def export_answers(quiz, access_token, question_id)
        case quiz.question_type
        when "OCQ" || "MCQ"    
            export_cq_answers(quiz, access_token, question_id)
        when "Free Text Question"
            # export_free_text_answer(ANNOTATION_ID, GROUP_ID , ACTIVITY_ID)
        end    
    end
    def export_cq_answers(quiz, access_token, question_id)
        quiz.online_answers.each do |answer|
            export_cq_answer(access_token, answer, question_id)
        end 
    end 
    def export_cq_answer(access_token, answer, question_id)
        query_url =	'https://staging-api.feedbackfruits.com/v1/engines/questions/choices'
        response = ""
        puts "<<<<<<<<export_cq_answer<<<<<<<<<<question_id<<<<<<<<<<<<<<<<"
        puts question_id
        puts "<<<<<<<<export_cq_answer<<<<<<<<<access_token<<<<<<<<<<<<<<<<"
        puts access_token
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "retreiving acess token from feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.post(query_url,
 
                :headers => {
                    'Content-Type' => 'application/vnd.api+json',
                    'Authorization'=>' Bearer '+access_token 
                    } ,
                # :body => '{"data":{"attributes":{"correct":'+answer.correct.to_s+',"body":"'+answer.answer+'"},"relationships":{"question":{"data":{"type":"multiple-choice-questions","id":"'+question_id+'"}}},"type":"questions/choices"}}'
                :body => '{"data":{"attributes":{"correct":false,"body":"CORRECT OPTION"},"relationships":{"question":{"data":{"type":"multiple-choice-questions","id":"'+question_id+'"}}},"type":"questions/choices"}}'
            )
        end	    
        puts "<<<<<<<<<<<<<<<<<<<<<<<<<<export_cq_answer response"
        puts response
        answer_created_successfuly = response.code==200
        return answer_created_successfuly
    end 
    # curl 'https://staging-api.feedbackfruits.com/v1/engines/questions/choices' 
    # -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1ODQ3MjgyNjEuNDEsImlzcyI6IkZlZWRiYWNrRnJ1aXRzIEFjY291bnRzIiwic2NvcGUiOiJhcGkudXNlcnMucmVhZCxhcGkuYWN0aXZpdHlfZ3JvdXBzLndyaXRlLGFwaS5hY3Rpdml0eV9ncm91cHMucmVhZCxhcGkuZW1haWxzLndyaXRlLGFwaS5lbWFpbHMucmVhZCxhcGkuaW52aXRhdGlvbnMud3JpdGUsYXBpLmludml0YXRpb25zLnJlYWQsYXBpLnZpZGVvcy53cml0ZSxhcGkudmlkZW9zLnJlYWQsYXBpLnZpZGVvX2ZyYWdtZW50cy53cml0ZSxhcGkudmlkZW9fZnJhZ21lbnRzLnJlYWQsYXBpLm9wZW5fcXVlc3Rpb25zLndyaXRlLGFwaS5vcGVuX3F1ZXN0aW9ucy5yZWFkLGFwaS5tdWx0aXBsZV9jaG9pY2VfcXVlc3Rpb25zLndyaXRlLGFwaS5tdWx0aXBsZV9jaG9pY2VfcXVlc3Rpb25zLnJlYWQsYXBpLmFubm90YXRpb25zLndyaXRlLGFwaS5hbm5vdGF0aW9ucy5yZWFkIiwic3ViIjoiY2NhZGNkMzQtNGI2OS00MTQ5LTg1ZDctMjEyNzIyYjhhZWYxIiwiaWF0IjoxNTg0NzI0NjYxLCJqdGkiOiI1ZTE5NDhmZS0xOGQwLTQxNDItOWM3Mi1kMTMwOWFlNWVlOGUifQ.hR9CDV-H3DwyQvnUvlo5UuTNLKDJahvrOl7uhsxqaMA' 
    # -H 'Content-Type: application/vnd.api+json' 
    # --data-binary '{"data":{"attributes":{"correct":true,"body":"CORRECT OPTION"},"relationships":{"question":{"data":{"type":"multiple-choice-questions","id":"29041754-0428-4230-97cc-f19e840d416f"}}},"type":"questions/choices"}}'

end


