require "retries"
module VimeoUtils
    
    def delete_video_from_vimeo_account(vid_vimeo_id)
        #clean up SL vimeo account
        state = false

        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "Video deletion Request failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end

        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            begin
              vimeo_video = VimeoMe2::Video.new(ENV["vimeo_token"],vid_vimeo_id)	
            rescue VimeoMe2::RequestFailed
                return state
            end      
            vimeo_video.destroy	
            state = true
        end      
        return state
    end	

    def delete_video_upload_record(vid_vimeo_id)
        #clean up VimeoUpload table
        vimeo_upload_record = VimeoUpload.find_by_vimeo_url("https://vimeo.com/"+vid_vimeo_id.to_s)
        vimeo_upload_record.destroy if vimeo_upload_record	
    end	

    def get_vimeo_video_name(vid_vimeo_id)
        query_url =	'https://api.vimeo.com/videos/'+vid_vimeo_id+'?fields=name'
        authorization = {"Authorization"=>@authorization}
        response = ""
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "retreiving video name on vimeo failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end
        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            response = HTTParty.get(query_url,headers:authorization)
        end	    
        updated_name = JSON.parse(response)['name']

        return updated_name
    end    

    def upload_video_to_vimeo(video_content,upload_link)
        headers = {'Content-Type' => 'application/offset+octet-stream'}
        headers['Upload-Offset'] = '0'
       
        uploaded = false
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "uploading video failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end
        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|     
            HTTParty.put(upload_link, body: video_content, headers: headers)
            uploaded = true
        end	
        
        return uploaded
    end    

    def get_vimeo_upload_raw_details    
        response = ""
        query_url = 'https://api.vimeo.com/me/videos'
        headers = {
            "Authorization" => 'bearer '+ENV['vimeo_token'],
            "Content-Type" => "application/json",
            "Accept" => "application/vnd.vimeo.*+json;version=3.4"
        }
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "retreiving testing upload details failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end
        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|     
            response = HTTParty.post(query_url, headers:headers)	      
        end	
        return response
    end    

    def get_transcoding_status(video_id)
        response = ""
        authorization = {"Authorization" => 'bearer '+ENV['vimeo_token']}
        query_url = "https://api.vimeo.com/videos/" + video_id + "?fields=transcode.status"
        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "getting transcoding status failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end
        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|     
            response = HTTParty.get(query_url,headers:authorization)
		end	    
        video_status = JSON.parse(response)['transcode']['status']
        return video_status 
    end    

    def check_if_video_exists(video_id)

        handler = Proc.new do |exception, attempt_number, total_delay|
            puts "Video lookup failed. saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."     
        end
        with_retries(:max_tries => 3, :base_sleep_seconds => 0.5, :max_sleep_seconds => 1.0, :handler => handler, :rescue => [Rack::Timeout::RequestTimeoutException, Timeout::Error, SocketError]) do |attempt_number|
            begin
              vimeo_video = VimeoMe2::Video.new(ENV["vimeo_token"],video_id)	
            rescue VimeoMe2::RequestFailed
                return false
            end      
        end      
        return true
    end    
end