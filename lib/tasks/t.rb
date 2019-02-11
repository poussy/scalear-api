# def inbox (results,cols)
    results = num_seek_fw_vs_lect_duration_normalized
    cols = ["minutes","seek_fw_count","lcount"]
    csv_file = CSV.generate do |csv_sheet|
        csv_sheet<<cols
        results.each do |r|
            csv_sheet<<[r["minutes"],r["seek_count"],r["lecture_count"]]
        end 
    end 

    file_name = Time.now.to_s+".zip"
    csv_file_name = "analytics_student_review.csv"
    t = Tempfile.new(file_name)
    Zip::ZipOutputStream.open(t.path) do |z|
        z.put_next_entry(csv_file_name)
        z.write(csv_file)
    end
    UserMailer.attachment_email(User.new(name:"poussy",email:"poussy@novelari.com"),Course.last, file_name, t.path, I18n.locale).deliver
    t.close
# end

#-----------------------------------------------------------------------------------#
def exec(q)
return ActiveRecord::Base.connection.execute(q)
end
#-----------------------------------------------------------------------------------#
num_seek_bw_vs_lect_duration_normalized_sql = '
select 
 (select floor(Lectures.duration/60.0)) as minutes, 
 (select count(Video_events.id)) as seek_count,
 (select count(Distinct(Lectures.id))) as lecture_count 
from Lectures 
inner join Video_events on Video_events.lecture_id=Lectures.id  
where Video_events.event_type = 3 AND from_time>to_time
group by minutes  
order by minutes;
'
num_seek_bw_vs_lect_duration_normalized=exec(num_seek_bw_vs_lect_duration_normalized_sql)

num_seek_fw_vs_lect_duration_normalized_sql = '
select 
 (select floor(Lectures.duration/60.0)) as minutes, 
 (select count(Video_events.id)) as seek_count,
 (select count(Distinct(Lectures.id))) as lecture_count 
from Lectures 
inner join Video_events on Video_events.lecture_id=Lectures.id  
where Video_events.event_type = 3 AND from_time<to_time
group by minutes  
order by minutes;
'
num_seek_fw_vs_lect_duration_normalized=exec(num_seek_fw_vs_lect_duration_normalized_sql)

#-----------------------------------------------------------------------------------#


    num_seek_bw__vs_num_q_per_vid_normalized_sql= " 
    SELECT COUNT(id)/lcount_per_q_per_lec.lcount as scount,q_per_lec.qcount,lcount_per_q_per_lec.lcount 
    FROM
        (SELECT COUNT(id) as qcount,lecture_id FROM online_quizzes GROUP BY lecture_id) q_per_lec
    INNER JOIN video_events ON video_events.lecture_id = q_per_lec.lecture_id
    INNER JOIN 
        (SELECT COUNT(lecture_id) as lcount,qcount 
         FROM (SELECT COUNT(id) as qcount,lecture_id FROM online_quizzes GROUP BY lecture_id) q_per_lec 
         GROUP BY qcount) lcount_per_q_per_lec ON q_per_lec.qcount=lcount_per_q_per_lec.qcount
    WHERE event_type = 3 AND from_time>to_time
    GROUP BY q_per_lec.qcount,lcount_per_q_per_lec.lcount
    ORDER BY q_per_lec.qcount
    "
    num_seek_fw__vs_num_q_per_vid_normalized_sql= " 
    SELECT COUNT(id)/lcount_per_q_per_lec.lcount as scount,q_per_lec.qcount,lcount_per_q_per_lec.lcount 
    FROM
        (SELECT COUNT(id) as qcount,lecture_id FROM online_quizzes GROUP BY lecture_id) q_per_lec
    INNER JOIN video_events ON video_events.lecture_id = q_per_lec.lecture_id
    INNER JOIN 
        (SELECT COUNT(lecture_id) as lcount,qcount 
         FROM (SELECT COUNT(id) as qcount,lecture_id FROM online_quizzes GROUP BY lecture_id) q_per_lec 
         GROUP BY qcount) lcount_per_q_per_lec ON q_per_lec.qcount=lcount_per_q_per_lec.qcount
    WHERE event_type = 3 AND from_time<to_time
    GROUP BY q_per_lec.qcount,lcount_per_q_per_lec.lcount
    ORDER BY q_per_lec.qcount
    "
