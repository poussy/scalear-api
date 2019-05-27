module VimeoUtils
    
    def delete_video_from_vimeo_account(vid_vimeo_id)
        #clean up SL vimeo account
        retries = 3
        delay = 1 
        ENV["VIMEO_DELETION_TOKEN"]="e6783970f529d6099598c4a7357a9aae"
        begin			
            vimeo_video = VimeoMe2::Video.new(ENV["VIMEO_DELETION_TOKEN"],vid_vimeo_id)	
            vimeo_video.destroy	
            state = true
        rescue 	VimeoMe2::RequestFailed
            state = false
        rescue Rack::Timeout::RequestTimeoutException ,Net::OpenTimeout
            fail "All retries are exhausted" if retries == 0
            puts "Video deletion Request failed. Retries left: #{retries -= 1}"
            sleep delay
            retry
            state = false
        end	
        return state
    end	

    def delete_video_upload_record(vid_vimeo_id)
        #clean up VimeoUpload table
        vimeo_upload_record = VimeoUpload.find_by_vimeo_url("https://vimeo.com/"+vid_vimeo_id.to_s)
        vimeo_upload_record.destroy if vimeo_upload_record	
    end	
end