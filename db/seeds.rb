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
