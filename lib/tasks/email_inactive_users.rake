namespace :gdpr do
    desc "called by heroku scheduler to prompt users to delete their accounts after 1 year of inactivity"
    task :email_inactive_users => :environment do
        inactive_users = User.where('updated_at < ? AND encrypted_data is null', 1.year.ago.midnight)
        inactive_users.find_in_batches(batch_size:1000) do |users_batch|
            UserMailer.delay.inactive_user(users_batch)
        end

    end
end
