namespace :clear_courses do
    users = [
        {
            id:1001,
            name: "Test_1",
            last_name: "student",
            screen_name: "studenttest1",
            university: "uni",
            email: "studenttest@sharklasers.com",
            password:"password1234"
        },
        {
            id:1002,
            name: "Test_2",
            last_name: "student",
            screen_name: "studenttest2",
            university: "uni",
            email: "studenttest2@sharklasers.com",
            password:"password1234"
        },
        {
            id:1003,
            name: "Test_3",
            last_name: "student",
            screen_name: "studenttest3",
            university: "uni",
            email: "studenttest3@sharklasers.com",
            password:"password1234"
        },
        {
            id:1004,
            name: "teacher",
            last_name: "1",
            screen_name: "teacher1@sharklasers.com",
            university: "uni",
            email: "teacher1@sharklasers.com",
            password:"password1234"
        },
        {
            id:1005,
            name: "teacher",
            last_name: "test",
            screen_name: "teacher test",
            university: "uni",
            email: "teacher2@sharklasers.com",
            password:"password1234"
        },
        {
            id:1006,
            name: "Administrator",
            last_name: "Control",
            screen_name: "Admin",
            university: "uniAdmin",
            email: "admin@scalear.com",
            password:"password1234"
        },
        {
            id:1007,
            name: "Test_1",
            last_name: "student",
            screen_name: "studenttestdomain",
            university: "uni",
            email: "student1@emaills.com",
            password: "password1234"
        }
    ]
    desc "task for clearing courses of E2E test"
    task :all_courses => :environment do
        users.each do |user|
            u = User.find_by_email(user[:email])
            u.subjects.destroy_all
            
            u.courses.destroy_all
            u.subjects_to_teach.destroy_all
        end
        
    end

    task :course_modules => :environment do
            u = User.find_by_email("teacher1@sharklasers.com")
            u.subjects_to_teach.all.each{|c| c.groups.destroy_all}
    end
    
    task :create_course => :environment do
        ## for fill_course
            u.courses.create(
                {id:1000,short_name: "csc-test", name: "aesting course 100", time_zone: "UTC",
                 description: '<p class=\"medium-editor-p\">too many words </p>', prerequisites: '<p class=\"medium-editor-p\">1- course 1 2- course 2...', discussion_link: "", 
                 image_url: "http://dasonlightinginc.com/uploads/2/9/4/2/294262...", unique_identifier: "SGVMJ-61635", guest_unique_identifier: "VGCDU-36581"}
            )
            [1001,1002,1003].each do |student_id|
                Enrollment.create(user_id:student_id,course_id:1000)
            end
            

    end

    task :clear_answers => :environment do
        FreeOnlineQuizGrade.destroy_all
        Confused.destroy_all
        FreeAnswer.destroy_all
        LectureView.destroy_all
        OnlineQuizGrade.destroy_all
        QuizGrade.destroy_all
        QuizStatus.destroy_all
        VideoEvent.destroy_all
    end

end
