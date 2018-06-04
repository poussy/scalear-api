namespace :gdpr do
    desc "called by heroku scheduler to pseudoanonymise inactive users"
    task :archive_users => :environment do
        # run on sunday
        if Date.today.wday == 0
            successes = {}
            failures = {}
            emails = [];
            inactive_users = User.where('updated_at < ? AND encrypted_data is null', 1.year.ago.midnight-1.week)
            inactive_users.each do |user|
            user_data = user.dup
            result = user.anonymise
                if result == "success"
                    successes[user.id] = result
                    emails << user_data.email
                else
                    failures[user.id] = result
                end
            end
            emails.each_slice(1000) do |batch|
                UserMailer.delay.anonymisation_success(batch)
            end
            UserMailer.anonymisation_report(ENV['anonymisation_report_mail'], successes, failures).deliver_now
        end
    end

end
