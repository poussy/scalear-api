class VimeoUploadsController < ApplicationController 
	include VimeoUtils
  def get_vimeo_video_id
		current_upload = VimeoUpload.find_by_lecture_id(params["id"].to_i)
		@vimeo_video_id = current_upload.vimeo_url.split('https://vimeo.com/')[1] if current_upload
		if current_upload==nil
			render json:{ vimeo_video_id: "none", :notice => ["lectures.no_video_upload"]}
	    elsif @vimeo_video_id
			render json:{ vimeo_video_id: @vimeo_video_id, :notice => ["lectures.vimeo_video_id_is_returned"]}
		else
			render json:{ :errors => "error"}, status: 400
		end
  end
    
  def get_uploading_status
		current_upload = VimeoUpload.find_by_lecture_id(params["id"].to_i)
		@progress = current_upload.status if current_upload
		if current_upload==nil
			render json: {status: "none", :notice => ["lectures.no_video_upload"]}
	    elsif @progress
			render json: {status: @progress, :notice => ["lectures.video_is_transcoding"]}
		else
			render json: {:errors => "error"}, status: 400
		end
	end	
	
	def get_vimeo_upload_details
		retries = 3 
		delay = 1 
		begin
			response = HTTParty.post('https://api.vimeo.com/me/videos',headers:{"Authorization"=>"bearer e6783970f529d6099598c4a7357a9aae","Content-Type"=>"application/json","Accept"=>"application/vnd.vimeo.*+json;version=3.4"})	
		rescue Rack::Timeout::RequestTimeoutException,  Net::OpenTimeout
			fail "All retries are exhausted" if retries == 0
			puts "get_vimeo_upload_details Request failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
		end	
		details = extract_upload_details(response)
		if response.code == 201 
			render json: { details:details, :notice => ["upload details is retreived successfully"]}
		else
			render json: {:errors => response['developer_message']}, status: 400
		end
    end	
    
    def extract_upload_details(response)
		video_info_access_token="b97fb8ab110c5aa54f73267911fc5051"#<<<<<<<<<----------env var
		parsed_response = JSON.parse(response)
		vimeo_video_id = parsed_response['uri'].split('videos/')[1]
		upload_link = parsed_response['upload']['upload_link']
		ticket_id = upload_link.match(/\?ticket_id=[0-9]*/)[0].split('=')[1]
		video_file_id = upload_link.match(/\&video_file_id=[0-9]*/)[0].split('=')[1]
		signature = upload_link.match(/\&signature=([0-9]*[a-zA-Z]*)*/)[0].split('=')[1]
		complete_url ='https://api.vimeo.com/users/96206044/uploads/'+ticket_id+'?video_file_id='+video_file_id+'&upgrade=true&signature='+signature
		details = {'complete_url':complete_url,'ticket_id':ticket_id,'upload_link_secure':upload_link,'video_id':vimeo_video_id,'video_info_access_token':video_info_access_token}
		return details
	end	

  def delete_complete_link
		ENV['vimeo_token']='e6783970f529d6099598c4a7357a9aae'
		retries = 3 
		delay = 1 
		begin
			response = HTTParty.delete(params[:link],headers:{"Authorization"=>"bearer "+ENV['vimeo_token']})
		rescue Rack::Timeout::RequestTimeoutException, Net::OpenTimeout
			fail "All retries are exhausted" if retries == 0
			puts "delete_complete_link Request failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
		end	
		if response.code == 201
			render json:{deletion:response, :notice => ["complete link deletion is done successfully"]}
		else 
			render json: {:errors => response['the completion link is not deleted']}, status:400
		end		
  end	

  def update_vimeo_table
		@lecture = Lecture.find(params['lecture_id'])
		if params["status"] == "complete" && params["status"]
			@new_vimeo_upload = VimeoUpload.find_by_vimeo_url(params["url"])
			@new_vimeo_upload.status = "complete"
			if @lecture.name == "New Lecture"
				@lecture.update(name:params["title"])
			end  
		else
				@new_vimeo_upload = VimeoUpload.new(:vimeo_url=>params["url"] ,:user_id => current_user.id ,:status => 'transcoding', :lecture_id => params['lecture_id'])
		end

		if @new_vimeo_upload.save
				render json: {new_vimeo_upload: @new_vimeo_upload, :notice => ["lectures.video_successfully_uploaded"]}
		else
				render json: {:errors => @new_vimeo_upload.errors}, status: 400
		end
	end	

  def update_vimeo_video_data
		retries = 3 
		delay = 1 
		ENV['vimeo_token']='e6783970f529d6099598c4a7357a9aae'
		video_edit_url = 'https://api.vimeo.com/videos/'+params[:video_id]
		authorization = {"Authorization"=>"bearer "+ENV['vimeo_token']}
		body = {name:params[:name],description:params[:description]}
		begin 
		 response=HTTParty.patch(video_edit_url,headers:authorization,body:body)
		rescue Rack::Timeout::RequestTimeoutException ,Net::OpenTimeout
			fail "All retries are exhausted" if retries == 0
			puts "update_vimeo_video_data failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
		end	
		if response.code == 200	
			render json: { video_update:response, :notice => ["update video name on vimeo is done successfully"]}
		else 
			render json: {:errors => response['video name on vimeo is not updated']}, status:400
		end		
	end	
	
	def delete_vimeo_video_angular
		@lecture = Lecture.find(params["lecture_id"])	
		lecture_url_not_used_elsewhere = Lecture.where(:url=>@lecture.url).count==1
		if lecture_url_not_used_elsewhere				
			vid_vimeo_id = params['vimeo_vid_id']
			state = delete_video_from_vimeo_account(vid_vimeo_id)
			delete_video_upload_record(vid_vimeo_id) 
			@lecture.update(url:"none")
			@lecture.update(duration:0)
	    end
		if state == true 
			render json:{ deletion:state ,:notice => ["video deletion is done successfully"]}		
		else 	 
			render json:{ :notice => ["video is not delete"]}	
		end	
  end	
end

