module FeedbackfruitUtils
  
    def get_fbf_access_token
        query_url =	'https://staging-accounts.feedbackfruits.com/auth/token'
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
                    :scope=>"api.users.read,api.activity_groups.write,api.activity_groups.read,api.emails.write,api.emails.read,api.invitations.write,api.invitations.read,api.videos.write,api.videos.read,api.video_fragments.write,api.video_fragments.read,api.open_questions.write,api.open_questions.read,api.multiple_choice_questions.write,api.multiple_choice_questions.read,api.annotations.write,api.annotations.read"
                }              
            )
        end	    
        
        access_token = response['access_token']
        return access_token
    end

  end