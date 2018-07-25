task :export_watched_video, [:course_array] => :environment do |t, args|

# for course in args[:course_array] do
    # thisCourse = Course.find_by_name(course)
    csv_files={}
    csv_files[:courses_statistics]= CSV.generate do |csv_course_statistics|
      csv_course_statistics << ["course name",'course id',"student id","knowledge video id","knowledge video name","knowledge video duration","percentage watched","number of seconds watched"]


      vid_duration = {}
      Course.where(name:['cc','cccc']).find_each do |c|
        for l in c.lectures
          vid_duration[l.id]= [l.name,l.duration]

        end
      end
      pp vid_duration

      Course.where(name:['cc','cccc']).find_each do |c|

         for e in c.enrollments
              LectureView.where(course_id:c.id, user_id: e.user_id).find_each do |lv|
                pp lv.lecture_id
                if (vid_duration[lv.lecture_id][1] != nil)
                   watch_time = (lv.percent)*vid_duration[lv.lecture_id][1]/100
                   pp watch_time
                   pp vid_duration[lv.lecture_id][1]
                   pp "------------------------------"
                else
                   watch_time = 0
                end
                csv_course_statistics << [c.name,c.id,e.user_id,lv.lecture_id,vid_duration[lv.lecture_id][0],vid_duration[lv.lecture_id][1],lv.percent,watch_time]
              end
         end
      end
    end



    csv_files[:courses_statistics_total_time]= CSV.generate do |csv_course_statistics|
      csv_course_statistics << ["course name","knowledge video name","knowledge video duration","total watch time"]


      vid = {}
      Course.where(name:['cc','cccc']).find_each do |c|
        for l in c.lectures
          vid[l.id]= [l.name,l.duration,0]

        end
      end
      pp vid
      watch_time = 0
      Course.where(name:['cc','cccc']).find_each do |c|

         for e in c.enrollments
              LectureView.where(course_id:c.id, user_id: e.user_id).find_each do |lv|
                pp lv.lecture_id
                if (vid[lv.lecture_id][1] != nil)
                   watch_time = (lv.percent)*vid[lv.lecture_id][1]/100
                   pp watch_time
                   pp vid[lv.lecture_id][1]
                   pp "------------------------------"
                   pp vid[lv.lecture_id][2]
                   vid[lv.lecture_id][2] = vid[lv.lecture_id][2]+watch_time
                else
                   watch_time = 0
                end
                csv_course_statistics << [c.name,vid[lv.lecture_id][0],vid[lv.lecture_id][1],vid[lv.lecture_id][2]]
              end

         end
      end
    end


    file_name = "course.zip"
    t = Tempfile.new(file_name)
    Zip::ZipOutputStream.open(t.path) do |z|
            csv_files.each do |key,value|
                    z.put_next_entry("#{key}.csv")
                    z.write(value)
            end
    end
    UserMailer.attachment_email(User.new(name:"poussy",email:"poussy@novelari.com"),Course.last, file_name, t.path, I18n.locale).deliver
    t.close
#
 end
