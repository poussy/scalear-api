# EDIT THIS FILE!!

namespace :db do
  desc "Erase and fill database"
  task :populate => :environment do
    require 'populator'
    require 'faker'
    
    #[Category, Product, Person].each(&:delete_all)
    # deleting all
    [User, Course, Lecture, Quiz, Question, Answer, QuizGrade, Enrollment].each(&:delete_all)
    
    
    # First user becomes a teacher role because I don't delete the user-role table!! fa automatic first is admin and next three are users
    User.populate 1 do |teacher|
      teacher.email   = "teacher@email.com"#Faker::Internet.email
      teacher.name = Faker::Name.name
      actual_password = "password"
      #digest = "#{actual_password}#{person.password_salt}"
      pepper = nil
      cost = 10 
      teacher.encrypted_password = ::BCrypt::Password.create("#{actual_password}#{pepper}", :cost => cost).to_s
      #person.encrypted_password = Digest::SHA1.hexdigest(digest)
      teacher.created_at=2.weeks.ago..Time.now
      teacher.updated_at=2.weeks.ago..Time.now
      #teacher.roles<<1
      #teacher.user_roles<<1
      #UserRole.populate 1 do |role|
      #  role.user_id= teacher.id
      #  role.role_id= 1
      #end    
    
      Course.populate 4 do |course|
        course.short_name= "10#{course.id}"
        course.name= Populator.words(1..3).titleize
        course.start_date= Time.now..2.weeks.from_now
        course.duration= 1..20
        course.user_id=teacher.id
        course.description= Populator.sentences(2..6)
        course.prerequisites= Populator.sentences(2..4)
        course.created_at=2.weeks.ago..Time.now
        course.updated_at=2.weeks.ago..Time.now
        
        User.populate 5 do |student|
          student.email   = "student#{student.id}@email.com" #Faker::Internet.email
          actual_password = "password"
          student.name = Faker::Name.name
          #digest = "#{actual_password}#{person.password_salt}"
          pepper = nil
          cost = 10 
          student.encrypted_password = ::BCrypt::Password.create("#{actual_password}#{pepper}", :cost => cost).to_s
          #person.encrypted_password = Digest::SHA1.hexdigest(digest)
          student.created_at=2.weeks.ago..Time.now
          student.updated_at=2.weeks.ago..Time.now
          #student.roles<<2
          #student.user_roles<<2
          
          #UserRole.populate 1 do |student_role|
          #  student_role.user_id= student.id
          #  student_role.role_id= 2
          #end
          Enrollment.populate 1 do |e|
            e.user_id=student.id
            e.course_id=course.id
          end
          
        Lecture.populate 2 do |lecture|
          lecture.name= Populator.words(1..3).titleize
          lecture.course_id=course.id
          lecture.description= Populator.sentences(2..6)
          lecture.url= "http://www.youtube.com/watch?v=OVLZ6tCOa1w"
        end
        
        Quiz.populate 2 do |quiz|
          quiz.course_id=course.id
          quiz.name= "Quiz#{quiz.id}"
          quiz.instructions= Populator.sentences(2..4)
          
          Question.populate 4 do |question|
            question.quiz_id=quiz.id
            question.content= Populator.sentences(1..3)
            
            Answer.populate 4 do |answer|
              answer.question_id=question.id
              answer.content=Populator.sentences(1..2)
              answer.correct=[true, false]
              
            QuizGrade.populate 0..1 do |grade|
              grade.user_id= student.id
              grade.quiz_id= quiz.id
              grade.question_id= question.id
              grade.answer_id= answer.id
              grade.grade= [1,0]
            end  
              
           end
           end
          end
        end  
      end
     end
    end
  end