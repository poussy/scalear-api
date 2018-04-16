users = [
    {
        name: "Test_1",
        last_name: "student",
        screen_name: "studenttest1",
        university: "uni",
        email: "studenttest@sharklasers.com",
        password:"password1234"
    },
    {
        name: "Test_2",
        last_name: "student",
        screen_name: "studenttest2",
        university: "uni",
        email: "studenttest2@sharklasers.com",
        password:"password1234"
    },
    {
        name: "Test_3",
        last_name: "student",
        screen_name: "studenttest3",
        university: "uni",
        email: "studenttest3@sharklasers.com",
        password:"password1234"
    },
    {
        name: "teacher",
        last_name: "1",
        screen_name: "teacher1@sharklasers.com",
        university: "uni",
        email: "teacher1@sharklasers.com",
        password:"password1234"
    },
    {
        name: "teacher",
        last_name: "test",
        screen_name: "teacher test",
        university: "uni",
        email: "teacher2@sharklasers.com",
        password:"password1234"
    },
    {
        name: "Administrator",
        last_name: "Control",
        screen_name: "Admin",
        university: "uniAdmin",
        email: "admin@scalear.com",
        password:"password1234"
    },
    {
        name: "Test_1",
        last_name: "student",
        screen_name: "studenttestdomain",
        university: "uni",
        email: "student1@emaills.com",
        password: "password1234"
    }
]


users.each do |user|
    puts user[:email]
    u =User.where(
        name: user[:name],
        email: user[:email],
        last_name: user[:last_name],
        screen_name: user[:screen_name],
        university: user[:university],
    ).first_or_initialize
    u.password = user[:password]
    u.completion_wizard=ActionController::Parameters.new( {"intro_watched"=>true} )
    u.skip_confirmation!
    u.save!
end


# 1000.times do |x|
#     u = User.create( 
#         name: "student-",
#         last_name: "#{x}",
#         screen_name: "student#{x}",
#         university: "uni",
#         email: "course_1_student#{x}@gmail.com",
#         password: "password1234")

#     c = Course.first
#     Enrollment.create(user_id:u.id, course_id: c.id,email_due_date: false)
#     8.times do |x|
#         Confused.create(user_id: u.id, course_id: c.id,lecture_id: 22,time: x+0.3, very: true, hide: false)
#     end
#     100.times do |x|
#         Confused.create(user_id: u.id, course_id: c.id,lecture_id: 1,time: x+0.3, very: false, hide: false)
#     end
#     100.times do |x|
#         Confused.create(user_id: u.id, course_id: c.id,lecture_id: 23,time: x+0.3, very: false, hide: false)
#     end
#     OnlineQuizGrade.create(lecture_id: 22, group_id: 1, course_id: 1, user_id: u.id, online_quiz_id: 47, online_answer_id: 58, grade: 1.0, optional_text: nil, review_vote: false, in_group: false, inclass: false, distance_peer: false, attempt: 2)
#     OnlineQuizGrade.create(lecture_id: 22, group_id: 1, course_id: 1, user_id: u.id, online_quiz_id: 48, online_answer_id: 60, grade: 0.0, optional_text: nil, review_vote: false, in_group: false, inclass: false, distance_peer: false, attempt: 2)
#     OnlineQuizGrade.create(lecture_id: 26, group_id: 1, course_id: 1, user_id: u.id, online_quiz_id: 51, online_answer_id: 65, grade: 0.0, optional_text: "Answer 1", review_vote: false, in_group: false, inclass: false, distance_peer: false, attempt: 1)
    
#     FreeOnlineQuizGrade.create(user_id: u.id, online_quiz_id: 38, online_answer: "sasasa", grade: 3.0, lecture_id: 1, group_id: 1, course_id: 1, response: "", hide: true, review_vote: false, attempt: 1)
#     FreeOnlineQuizGrade.create(user_id: u.id, online_quiz_id: 50, online_answer: "sasasa", grade: 3.0, lecture_id: 1, group_id: 1, course_id: 1, response: "", hide: true, review_vote: false, attempt: 1)
    
    
# end