namespace :gdpr do
   
    desc "called by heroku scheduler to prompt users to delete their accounts after 1 year of inactivity"
    task :email_inactive_users => :environment do
        inactive_users = User.where('updated_at < ? AND encrypted_data is null', 1.year.ago.midnight)
        inactive_users.each do |user|
            UserMailer.inactive_user(user,I18n.locale).deliver
        end

    end

    task :pseudoanonymise_inactive_users => :environment do
        successes = {}
        failures = {}
        inactive_users = User.where('updated_at < ? AND encrypted_data is null', 1.year.ago.midnight-1.week)
        inactive_users.each do |user|
                
            user.encrypted_email = Digest::SHA256.hexdigest (user.email).to_s
            
            # len   = ActiveSupport::MessageEncryptor.key_len
            # salt  = SecureRandom.random_bytes(len)

            ## use email as key for encryption
            key   = ActiveSupport::KeyGenerator.new(user.email).generate_key(ENV['gdpr_salt'],32)
            crypt = ActiveSupport::MessageEncryptor.new(key)
            encrypted_name = crypt.encrypt_and_sign(user.name)   
            encrypted_screen_name = crypt.encrypt_and_sign(user.screen_name)   
            encrypted_last_name = crypt.encrypt_and_sign(user.last_name)
            encrypted_university = crypt.encrypt_and_sign(user.university)
            user.encrypted_data = {'name' => encrypted_name, 'last_name' => encrypted_last_name, 
                'screen_name' => encrypted_screen_name,'university' => encrypted_university}
            user.name = "Archived"
            user.last_name = "user"
            user.screen_name = "Archived#{user.id}"
            user.university = "Archived"
            user.email = "archived_user#{user.id}@scalable-learning.com"
            user.skip_confirmation!
            user.skip_reconfirmation!
            if user.save
                successes[user.id.to_s] = "success"
            else
                failures[user.id.to_s] = user.errors.map{|attr,err| [attr,err] }.flatten
            end
        end
        UserMailer.anonymisation_report(ENV['gdpr_report_mail'], successes, failures).deliver

    end

end
