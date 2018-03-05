namespace :gdpr do
    desc "called by heroku scheduler to prompt users to delete their accounts after 1 year of inactivity"
    task :email_inactive_users => :environment do
        inactive_users = User.where('updated_at < ? AND encrypted_data is null', 1.year.ago.midnight)
        inactive_users.each do |user|
            UserMailer.inactive_user(user,I18n.locale).deliver
        end

    end
end
