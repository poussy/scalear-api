

namespace :db do
  desc "Export all courses whose teacher mail is not archived as canvas and send it to course owner email"
  task export_all_active_courses: :environment do
    include CanvasCommonCartridge::Converter
    include HelperExportCourseAsText
    def send_course_to_teacher_mail(course,teacher,course_file)
        tmp = Packager.new
        tmp.pack_to_ccc(course,teacher,false,true,course_file) 
    end 
    def export_all_courses
        unarchived_teacher_ids = TeacherEnrollment.joins(:user).where("email not like ?","%archived%").uniq.pluck(:user_id)
        courses_to_export = Course.where("user_id in (?)",unarchived_teacher_ids).uniq
        for course in courses_to_export do
           
            course_file = write_course(course)
            send_course_to_teacher_mail(course,course.teachers[0],course_file) 
          
            # sleep 108000 # 30 minutes in seconds
        end 
    end 
    if Date.today == Date.new(2020,12,10)
        export_all_courses
    end
  end
end
