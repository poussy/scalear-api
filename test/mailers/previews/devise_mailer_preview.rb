class Devise::MailerPreview < ActionMailer::Preview
    def confirmation_instructions
        Devise::Mailer.confirmation_instructions(User.first,"token")
    end

    def reset_password_instructions
        Devise::Mailer.reset_password_instructions(User.first,"token")
    end
end
