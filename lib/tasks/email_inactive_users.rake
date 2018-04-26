namespace :gdpr do
    desc "called by heroku scheduler to prompt users to delete their accounts after 1 year of inactivity"
    task :email_inactive_users => :environment do
        inactive_users = User.where('updated_at < ? AND encrypted_data is null', 1.year.ago.midnight)
        inactive_users.pluck(:email).each_slice(1000) do |emails_batch|
            UserMailer.delay.inactive_user(emails_batch)
        end

    end
end
