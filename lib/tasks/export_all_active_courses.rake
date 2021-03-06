

namespace :db do
  desc "Export all courses whose teacher mail is not archived as canvas and send it to course owner email"
  task export_all_active_courses: :environment do
    include CanvasCommonCartridge::Converter
  
    def send_course_to_teacher_mail(course,teacher)
        tmp = Packager.new
        tmp.pack_to_ccc(course,teacher,false,true) 
    end 

    def export_all_courses
        unarchived_teacher_ids = TeacherEnrollment.joins(:user).where("email not like ?","%archived%").uniq.pluck(:user_id)
        courses_to_export = Course.where("user_id in (?)",unarchived_teacher_ids).uniq
     
        for course in courses_to_export do
            puts "exporting all courses - course name:"+course.name
            send_course_to_teacher_mail(course,course.teachers[0])     
        end 
    end 
    if Date.today == Date.new(2020,12,16)
        export_all_courses #all active
    end
  end
end
