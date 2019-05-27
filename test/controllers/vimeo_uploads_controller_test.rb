require 'test_helper'
 

class VimeoUploadsControllerTest < ActionDispatch::IntegrationTest
    def setup
        #lecture 1 transcoding
        vimeo_upload_1=VimeoUpload.new(user_id:1,vimeo_url:'https://vimeo.com/123',status:'transcoding',lecture_id:1)
        #lecture 2 complete
        vimeo_upload_2=VimeoUpload.new(user_id:1,vimeo_url:'https://vimeo.com/246',status:'complete',lecture_id:2)
       
        vimeo_upload_1.save
        vimeo_upload_2.save

        @authorization = 'bearer '+ENV['vimeo_token']
    end    

    #vimeo video properly uploaded
    test 'vimeo video id should be returned' do 
      get "/vimeo_uploads/get_vimeo_video_id",
      params:{'id':1}
   
      assert_equal decode_json_response_body['vimeo_video_id'],'123'
    end 

    #vimeo video link inserted
    test 'vimeo video id should be returned as none' do 
      get "/vimeo_uploads/get_vimeo_video_id",
      params:{'id':3}
  
      assert_equal decode_json_response_body['vimeo_video_id'] ,'none'
    end    

    #vimeo video transcoding
    test 'uploading status should be transcoding' do
       get '/vimeo_uploads/get_uploading_status',
       params:{'id':1}

       assert_equal decode_json_response_body['status'] ,'transcoding'
    end

    #vimeo video transcoding complete
    test 'uploading status should be complete' do
        get '/vimeo_uploads/get_uploading_status',
        params:{'id':2}
 
        assert_equal decode_json_response_body['status'] ,'complete'
    end
    
    #vimeo video was not uploded, it was inserted as a link 
    test 'uploading status should be none' do
        get '/vimeo_uploads/get_uploading_status',
        params:{'id':3}
 
        assert_equal decode_json_response_body['status'] ,'none'
    end  

    #retreiving necessary upload info that should be passed to FE
    test 'upload details should be returned' do
         get '/vimeo_uploads/get_vimeo_upload_details'        
         details = decode_json_response_body['details']

         assert_equal details.keys , ['complete_url','ticket_id','upload_link_secure','video_id','video_info_access_token']
         assert details['upload_link_secure'].include?(details['ticket_id']), true
         assert details['complete_url'].include?(details['ticket_id']), true       
    end  

    # #vimeo server response for upload details querry,is broken into fields
    test 'uploading fields should be extracted' do
        retries = 3 
		delay = 1 
		begin
            response = HTTParty.post('https://api.vimeo.com/me/videos',headers:{"Authorization"=>@authorization,"Content-Type"=>"application/json","Accept"=>"application/vnd.vimeo.*+json;version=3.4"})
        rescue Rack::Timeout::RequestTimeoutException,  Net::OpenTimeout
			fail "All retries are exhausted" if retries == 0
			puts "get_vimeo_upload_details Request failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
		end	    	
        vimeoUploadCtrl = VimeoUploadsController.new
        details = vimeoUploadCtrl.extract_upload_details(response)

        parsed_response = JSON.parse(response)

        vimeo_video_id = parsed_response['uri'].split('videos/')[1]
        upload_link = parsed_response['upload']['upload_link']

        assert_equal details[:video_id], vimeo_video_id
        assert_equal details[:upload_link_secure], upload_link
        assert details[:upload_link_secure].include?('.cloud.vimeo.com'), true
    end  

    test 'complete_url should be deleted' do
        #generate upload details to get the compelete_url
        retries = 3 
        delay = 1 
        begin
            response = HTTParty.post('https://api.vimeo.com/me/videos',headers:{"Authorization"=>@authorization,"Content-Type"=>"application/json","Accept"=>"application/vnd.vimeo.*+json;version=3.4"})	
        rescue Rack::Timeout::RequestTimeoutException, Net::OpenTimeout
			fail "All retries are exhausted" if retries == 0
			puts "retreiving testing upload details failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
		end	
        vimeoUploadCtrl = VimeoUploadsController.new
        details = vimeoUploadCtrl.extract_upload_details(response)

        #upload a file 
        headers = {'Content-Type' => 'application/offset+octet-stream'}
        headers['Upload-Offset'] = '0'
        video_content = fixture_file_upload('files/test_video.mov','video/quicktime').read(469000).to_s
        begin
            HTTParty.put(details[:upload_link_secure], body: video_content, headers: headers)
        rescue Rack::Timeout::RequestTimeoutException, Net::OpenTimeout
			fail "All retries are exhausted" if retries == 0
			puts "uploading video failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
		end	
        #delete the complete_url
        delete '/vimeo_uploads/delete_complete_link',
        params:{
            link:details[:complete_url]
        }

        #if the complete url is deleted the status of the video transcode will be transcoding
        authorization = {"Authorization"=>@authorization}
        query_url = "https://api.vimeo.com/videos/" + details[:video_id] + "?fields=transcode.status"
        retries = 3
        delay = 1 
        begin
            response = HTTParty.get(query_url,headers:authorization)
        rescue Rack::Timeout::RequestTimeoutException ,Net::OpenTimeout
			fail "All retries are exhausted" if retries == 0
			puts "getting transcoding status failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
			state = false
		end	    
        video_status = JSON.parse(response)['transcode']['status']

        #check the video status
        assert_equal video_status,'in_progress'

        # #clean up SL vimeo account
        retries = 3
        delay = 1 
        begin	
            vimeo_video = VimeoMe2::Video.new(ENV['vimeo_token'],details[:video_id])
            vimeo_video.destroy
        rescue Rack::Timeout::RequestTimeoutException ,Net::OpenTimeout
            puts "Video deletion Request failed. Retries left: #{retries -= 1}"
			sleep delay
            retry
        end        
    end  

    test 'vimeo table should be updated with new record' do
        @user = users(:user4)
        @headers2 =  @user.create_new_auth_token
    	@headers2['content-type']="application/json"

        post '/vimeo_uploads/update_vimeo_table',
        params:{
            lecture_id:3,
            url:"https://vimeo.com/567"
        }, 
        headers: @headers2 , as: :json

        last_upload_record = VimeoUpload.last
        assert_equal last_upload_record.user_id,4
        assert_equal last_upload_record.vimeo_url,"https://vimeo.com/567"
        assert_equal last_upload_record.status,'transcoding'
        assert_equal last_upload_record.lecture_id,3
        
    end  
    test 'vimeo table should be updated with complete and lecture title is set' do
        @user = users(:user4)
        @headers2 =  @user.create_new_auth_token
    	@headers2['content-type']="application/json"
        l4 = Lecture.find(4)
        l4.update(:url=>"https://vimeo.com/567",:name=>'New Lecture')
        
        VimeoUpload.create(:vimeo_url=>"https://vimeo.com/567" ,:user_id => @user.id ,:status => 'transcoding', :lecture_id => 4)
       
        post '/vimeo_uploads/update_vimeo_table',
        params:{
            lecture_id: 4,
            url:"https://vimeo.com/567",
            status:'complete',
            title:'My Video'
        }, 
        headers: @headers2 , as: :json

        updated_lecture =  Lecture.find(4)
        updated_record = VimeoUpload.find_by_vimeo_url('https://vimeo.com/567')

        assert_equal updated_record.user_id, 4
        assert_equal updated_record.vimeo_url, "https://vimeo.com/567"
        assert_equal updated_record.status, 'complete'
        assert_equal updated_record.lecture_id, 4
        assert_equal updated_lecture.name, 'My Video'
    end  

    test 'video name should be updated on vimeo' do
        #get the actual name of the video on vimeo
        testing_video_id = '338647269'
        query_url =	'https://api.vimeo.com/videos/'+testing_video_id+'?fields=name'
        authorization = {"Authorization"=>@authorization}
        retries = 3 
		delay = 1 
		begin
            vimeo_video = VimeoMe2::Video.new(ENV['vimeo_token'],testing_video_id)
        rescue Rack::Timeout::RequestTimeoutException, Net::OpenTimeout
            fail "All retries are exhausted" if retries == 0
            puts "retreiving video name on vimeo failed. Retries left: #{retries -= 1}"
            sleep delay
            retry
        end	

        old_name = vimeo_video.name

        #generate random number 
        num = rand(1..1000)
     
        #stick the random number into the name 
        new_name=old_name.split("_")[0]+"_"+num.to_s

        #update the video name with the new one
        post '/vimeo_uploads/update_vimeo_video_data',
        params:{
            name:new_name,
            video_id:testing_video_id
        }

        #check the name is properly updated
        response = HTTParty.get(query_url,headers:authorization)
        updated_name = JSON.parse(response)['name']

        assert_equal updated_name, new_name

    end  

    test 'video should be deleleted from Vimeo account and its record deleted from VimeoUpload table' do
        #upload a test video to vimeo using vimeome2  
        #video/quicktime
        video = fixture_file_upload('files/test_video.mov','video/quicktime')   
        retries = 3
        delay = 1 
        begin	    
         vimeo_client = VimeoMe2::User.new(ENV['vimeo_token'])
        rescue Rack::Timeout::RequestTimeoutException ,Net::OpenTimeout
			fail "All retries are exhausted" if retries == 0
			puts "Uploading test video failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
		end
        video_link = 'http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4'
        vimeo_client.pull_upload 'to be deleted',video_link
    
        #find its vimeo video id
        list =  vimeo_client.get_video_list
        videoToBeDeleted = list['data'][0]
        vimeo_vid_id = videoToBeDeleted['uri'].split('/')[2]
        Lecture.find(4).update(url:videoToBeDeleted['uri'])

        #delete it with tested function
        delete '/vimeo_uploads/delete_vimeo_video_angular',
        params:{
            lecture_id:4,
            vimeo_vid_id:vimeo_vid_id
        }

        #search for this uploaded video id at SL Vimeo account 
        query_url = 'https://api.vimeo.com/videos?query='+vimeo_vid_id.to_s
        authorization = {"Authorization"=>@authorization}
        retries = 3 
		delay = 1 
		begin
            response=HTTParty.get(query_url,headers:authorization)
        rescue Rack::Timeout::RequestTimeoutException, Net::OpenTimeout
			fail "All retries are exhausted" if retries == 0
			puts "searching for the video file failed. Retries left: #{retries -= 1}"
			sleep delay
			retry
		end	    
        number_results_search_query = JSON.parse(response)['total']

        #check the search result to be nil 
        assert_equal number_results_search_query,0

        #check lecture details are reset
        updatedLecture = Lecture.find(4)
        assert_equal updatedLecture.url,"none"
        assert_equal updatedLecture.duration,0

        #check this video upload record is removed
        assert_nil VimeoUpload.find_by_lecture_id(4) 
    end  

end