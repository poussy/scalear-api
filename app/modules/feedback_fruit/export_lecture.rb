module FeedbackFruit::ExportLecture
    include  FeedbackFruit::ExportQuestion
    def export_to_fbf(url, teacher_email, title, lecture)
        # teacher_email = 'poussy.amr.nileu@gmail.com'
        #get access token
        access_token = get_fbf_access_token
        #get acvitivty group id
        group_id = get_group_id(access_token)
        #get media id 
        media_id = get_media_id(url,access_token)
        #get video activity id
        activity_video_id = get_activity_video_id(media_id,title,group_id,access_token)
        #attach activity id to activity group
        attachment_accomplished = attach_video_activity_to_group(group_id,activity_video_id,access_token)
        #register teacher email
        if attachment_accomplished
            #send teacher invitation
            export_video_quizzes(lecture.online_quizzes, access_token,activity_video_id, group_id)
            email_id = register_teacher_email_on_fbf(teacher_email,access_token)
            puts '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<invitation sent>>>>>>>>>>>>>>>>>>>>>'
            invitation_accomplished = send_teacher_invitation_on_fbf_video(email_id,group_id,access_token)  
            return activity_video_id
        end    
        return false
    end     
    def get_fbf_access_token
        query_url =	'https://accounts.feedbackfruits.com/auth/token'
        response = ""
        
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "retreiving acess token from feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.post(query_url,
                :headers => { 'Content-Type' => 'application/x-www-form-urlencoded' } ,
                :body=>{
                    :client_id=>ENV['fbf_client_id'],
                    :client_secret=>ENV['fbf_client_secret'],
                    :grant_type=>'password',
                    :username=>"poussy@novelari.com",
                    :password=>"poussy123",
                    :scope=>"api.users.read,api.activity_groups.write,api.activity_groups.read,api.emails.write,api.emails.read,api.invitations.write,api.invitations.read,api.videos.write,api.videos.read,api.video_fragments.write,api.video_fragments.read,api.open_questions.write,api.open_questions.read,api.multiple_choice_questions.write,api.multiple_choice_questions.read,api.annotations.write,api.annotations.read,api.questions.choices.write,api.questions.choices.read"
                }              
            )
        end	    
        #if repsonse code not 200 raise exception
        access_token = response['access_token']
        return access_token
    end
    def get_group_id(access_token)
        query_url =	'https://api.feedbackfruits.com/v1/activity_groups'
        response = ""

        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "retreiving group_id from feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.post(query_url,
                :headers => { 'Content-Type' => 'application/vnd.api+json','Authorization'=>'Bearer '+access_token } ,
                :body=>'{"data":{"attributes":{"enrollability":"open"},"relationships":{"extension":{"data":{"type":"extensions","id":"video"}}},"type":"activity-groups"}}'         
            )
        end	    
        group_id=response.parsed_response['data']['id']
       return group_id
    end    
    def get_media_id(url,access_token)
        query_url =	'https://media.feedbackfruits.com'
        response = ""
        pp "<<<<<<<<<<<<<<<<<<<<< getting media id >>>>>>>>>>>>>>>>>>>>."
        pp Time.now.strftime("%d/%m/%Y %H:%M")
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "retreiving media_id from feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.post(query_url,
                :headers => { 'Content-Type' => 'application/x-www-form-urlencoded','Authorization'=>'Bearer '+access_token } ,
                :body=>{
                    :url=>url
                }              
            )
        end	 
        pp "------------------------------------------------------------"
        pp Time.now.strftime("%d/%m/%Y %H:%M")
        media_id = response.parsed_response['id']   
        return media_id
    end
    def get_activity_video_id(media_id,title,group_id,access_token)
        query_url =	'https://api.feedbackfruits.com/v1/engines/multimedia/videos'
        response = ""
        
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "retreiving activity_video_id from feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.post(query_url,
                :headers => { 'Content-Type' => 'application/vnd.api+json','Authorization'=>'Bearer '+access_token } ,
                :body=>'{"data":{"attributes":{"title":"' +title+ '"},' +
                '"relationships":{"media":{"data":{"type":"media","id":"' +media_id+ '"}},' +
                '"extension":{"data":{"type":"extensions","id":"video"}},' +
                '"group":{"data":{"type":"activity-groups","id":"' +group_id + '"}}},"type":"videos"}}'
            )
        end	    
        activity_video_id=response.parsed_response['data']['id']
       return  activity_video_id
    end
    def attach_video_activity_to_group(group_id,activity_video_id,access_token)
        query_url =	'https://api.feedbackfruits.com/v1/activity_groups/' + group_id
        response = ""
        
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "attach_video_activity_to_group on feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.patch(query_url,
                :headers => { 'Content-Type' => 'application/vnd.api+json','Authorization'=>'Bearer '+access_token } ,
                :body=>'{"data":{"id":"' + group_id + '",' +
                '"attributes":{},' +
                '"relationships":{"activity":{"data":{"type":"videos","id":"' + activity_video_id + '"}},' +
                '"extension":{"data":{"type":"extensions","id":"video"}}},"type":"activity-groups"}}'
            )
        end	    
       attach_successful = response.code==200
       return attach_successful
    end
    def register_teacher_email_on_fbf(teacher_email,access_token)
        #retreive teacher email_id if it's already registered
        query_url =	'https://api.feedbackfruits.com/v1/emails'
        response = ""
        
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "register_teacher_email_on_fbf on feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.post(query_url,
                :headers => { 'Content-Type' => 'application/vnd.api+json','Authorization'=>'Bearer '+access_token } ,
                :body=>'{"data":{"attributes":{"address":"' + teacher_email + '"},"type":"emails"}}'
            )
        end	    
        email_id = response.parsed_response['data']['id']
       return email_id
    end
    def send_teacher_invitation_on_fbf_video(email_id,group_id,access_token)
        query_url =	'https://api.feedbackfruits.com/v1/invitations'
        response = ""
        
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "send_teacher_invitation_on_fbf_video on feedback fruit failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.post(query_url,
                :headers => { 'Content-Type' => 'application/vnd.api+json','Authorization'=>'Bearer '+access_token } ,
                :body=>'{"data":{"attributes":{"admin":true,"status":"pending"},"relationships":{"group":{"data":{"type":"activity-groups","id":"' + group_id + '"}},"email":{"data":{"type":"emails","id":"' + email_id + '"}}},"type":"invitations"}}'
            )
        end	    
        invitation_accomplished = response.code==200
       return invitation_accomplished
    end
    def is_youtube(url)
       return  url.include?('www.youtube.com')
    end 

  end