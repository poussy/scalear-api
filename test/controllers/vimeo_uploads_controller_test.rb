require 'test_helper'

class VimeoUploadsControllerTest < ActionDispatch::IntegrationTest
    include VimeoUtils
    def setup
        #lecture 1 transcoding
        vimeo_upload_1=VimeoUpload.new(user_id:1,vimeo_url:'https://vimeo.com/123',status:'transcoding',lecture_id:1)
        #lecture 2 complete
        vimeo_upload_2=VimeoUpload.new(user_id:1,vimeo_url:'https://vimeo.com/246',status:'complete',lecture_id:2)
       
        vimeo_upload_1.save
        vimeo_upload_2.save
      
        @authorization = 'bearer '+ENV['vimeo_token']
    end    
    #reset lecture4 as in lectures.yml
    def teardown
    l4 = Lecture.find(4)
    l4.update(
        name:'lecture4',
        url: "http://www.youtube.com/watch?v=xGcGdfrty",
        duration: 150
    )
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
         #retreive upload details, which create a temp video on SL vimeo account
         get '/vimeo_uploads/get_vimeo_upload_details'        
         details = decode_json_response_body['details']

         assert_equal details.keys , ['complete_url','ticket_id','upload_link_secure','video_id','video_info_access_token']
         assert details['upload_link_secure'].include?(details['ticket_id']), true
         assert details['complete_url'].include?(details['ticket_id']), true    
         
         #remove the temp video
         delete_video_from_vimeo_account(details['video_id'])
    end  

    test 'complete_url should be deleted' do
        #generate upload details to get the compelete_url
        raw_details = get_vimeo_upload_raw_details
        vimeoUploadCtrl = VimeoUploadsController.new
        details = vimeoUploadCtrl.extract_upload_details(raw_details)

        #upload a file 
        video_content = fixture_file_upload('files/test_video.mov','video/quicktime').read(469000).to_s
        upload_video_to_vimeo(video_content,details[:upload_link_secure])
        
        #delete the complete_url
        delete '/vimeo_uploads/delete_complete_link',
        params:{
            link:details[:complete_url]
        }

        #if the complete url is deleted the status of the video transcode will be transcoding
        video_status = get_transcoding_status(details[:video_id])
        #check the video status
        assert_equal video_status,'in_progress'

        # #clean up SL vimeo account
        delete_video_from_vimeo_account(details[:video_id])    
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
        testing_video_id = '338886505'
   
        #generate random number 
        num = rand(1..1000)
     
        #stick the random number into the name 
        new_name="unit test"+"_"+num.to_s

        #update the video name with the new one
        post '/vimeo_uploads/update_vimeo_video_data',
        params:{
            name:new_name,
            video_id:testing_video_id
        }

        #check the name is properly updated
        updated_name = get_vimeo_video_name(testing_video_id)

        assert_equal updated_name, new_name

    end  

    test 'video should be deleleted from Vimeo account and its record deleted from VimeoUpload table' do
        #upload a test video to vimeo 
        ##generate upload details to get the compelete_url
        raw_details = get_vimeo_upload_raw_details
        vimeoUploadCtrl = VimeoUploadsController.new
        details = vimeoUploadCtrl.extract_upload_details(raw_details)

        ##upload a file 
        video_content = fixture_file_upload('files/test_video.mov','video/quicktime').read(469000).to_s
        upload_video_to_vimeo(video_content,details[:upload_link_secure])
        
        #delete it with tested function
        delete '/vimeo_uploads/delete_vimeo_video_angular',
        params:{
            lecture_id:4,
            vimeo_vid_id:details[:video_id]
        }

        #check whether the uploaded video id exists 
        exists = check_if_video_exists(details[:video_id])

        #make sure the video doesn't exist
        assert_equal exists,false

        #check lecture details are reset
        updatedLecture = Lecture.find(4)
        assert_equal updatedLecture.url,"none"
        assert_equal updatedLecture.duration,0

        #check this video upload record is removed
        assert_nil VimeoUpload.find_by_lecture_id(4) 
    end  

    #vimeo server response for upload details querry,is broken into fields
    test 'uploading fields should be extracted' do 
        #ask vimeo server for uploading details , which create a temp empty video on SL account 
        raw_details = get_vimeo_upload_raw_details

        #extract the upload details from the server response
        vimeoUploadCtrl = VimeoUploadsController.new
        details = vimeoUploadCtrl.extract_upload_details(raw_details)

        parsed_response = JSON.parse(raw_details)

        vimeo_video_id = parsed_response['uri'].split('videos/')[1]
        upload_link = parsed_response['upload']['upload_link']

        #make sure the fields are correclty deduced
        assert_equal details[:video_id], vimeo_video_id
        assert_equal details[:upload_link_secure], upload_link
        assert details[:upload_link_secure].include?('.cloud.vimeo.com'), true

        #remove the temp video
        delete_video_from_vimeo_account(details[:video_id])
    end  

end