# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
    def announcement_email
        UserMailer.announcement_email("okasha@gmail.com", Announcement.first, Course.first, I18n.locale)
    end
    def password_changed_email
        UserMailer.password_changed_email(User.first,I18n.locale)
    end
    def anonymisation_success
        UserMailer.anonymisation_success(User.first)
    end

    def attachment_email
        UserMailer.attachment_email(User.first, Course.first, "my_module.csv", Rails.root.join('public','assets','images','logo_banner.jpg'), I18n.locale)
    end

    def contact_us_email
        UserMailer.contact_us_email("courses/1/modules/1/lectures/1", User.first, "Something is broken", "Chrome")
    end

    def content_problem_email
        UserMailer.content_problem_email("/courses/1/modules/1/lectures/1", User.find(98), "Problem with lecture content", Course.first, -1, Lecture.first, -1 , "chrome","1")
    end

    def course_end_date_email
        UserMailer.course_end_date_email(User.first, Course.first, I18n.locale)
    end

    def discussion_reply_email
        comment = Forum::Comment.new(content:"<p class=\"medium-editor-p\">comment on question1</p>")
        UserMailer.discussion_reply_email(User.first, User.find(98), Course.first, Group.first, Lecture.first, Forum::Post.find(1), comment, I18n.locale)
    end

    def due_date_email
        UserMailer.due_date_email(User.first , Course.find(14) , Lecture.first , "Lecture" ,I18n.locale)
    end

    def inactive_user
        UserMailer.inactive_user(User.first, I18n.locale)
    end

    def progress_days_late
        UserMailer.progress_days_late(User.first, "my_module.csv", Rails.root.join('public','assets','images','logo_banner.jpg'), I18n.locale,Course.first)
    end

    def survey_email
        UserMailer.survey_email(1,"<p class=\"medium-editor-p\">question 1</p>","answer to question","survey 1",Course.first,"response to question 1", I18n.locale)
    end

    def teacher_discussion_email
        UserMailer.teacher_discussion_email(User.find(98), User.first, Course.first, Group.first, Lecture.first, Forum::Post.find(1), I18n.locale)
    end

    def teacher_email
        UserMailer.teacher_email(Course.first, "teacher1@gmail.com", 3, I18n.locale)
    end

    def technical_problem_email
        UserMailer.technical_problem_email("/courses/1/groups/1/lectures/1", User.first, "problem with the video loading", Course.first, Group.first, Lecture.first, Quiz.first, "Chrome","problem_type","version 1.1")
    end

    def video_events
        UserMailer.video_events(User.first,"my_module.csv", Rails.root.join('public','assets','images','logo_banner.jpg'), I18n.locale, "module2", "course1")
    end


end
