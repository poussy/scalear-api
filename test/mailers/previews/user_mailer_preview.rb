# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
    def password_changed_email
        UserMailer.password_changed_email(User.first,I18n.locale)
    end

end
