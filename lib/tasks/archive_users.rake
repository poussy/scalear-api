namespace :gdpr do
    desc "called by heroku scheduler to pseudoanonymise inactive users"
    task :archive_users => :environment do
        successes = {}
        failures = {}
        inactive_users = User.where('updated_at < ? AND encrypted_data is null', 1.year.ago.midnight-1.week)
        inactive_users.each do |user|
           user_data = user.dup
           result = user.anonymise
           if result == "success"
                successes[user.id] = result
                UserMailer.delay.anonymisation_success(user_data)#.deliver
           else
                failures[user.id] = result
           end
        end
        UserMailer.anonymisation_report(ENV['anonymisation_report_mail'], successes, failures).deliver

    end

end
