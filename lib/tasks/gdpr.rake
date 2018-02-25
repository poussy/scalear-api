namespace :gdpr do
   
    desc "called by heroku scheduler to prompt users to delete their accounts after 1 year of inactivity"
    task :email_inactive_users => :environment do
        inactive_users = User.where('updated_at < ?', 1.year.ago.midnight)
        inactive_users.each do |user|
            UserMailer.inactive_user(user,I18n.locale).deliver
        end

    end

    task :pseudoanonymise_inactive_users => :environment do
        inactive_users = User.where('updated_at < ?', 1.year.ago.midnight-1.week)
        inactive_users.each do |user|
                
            user.encrypted_email = Digest::SHA256.hexdigest (user.email).to_s
            
            # len   = ActiveSupport::MessageEncryptor.key_len
            # salt  = SecureRandom.random_bytes(len)

            ## use email as key for encryption
            key   = ActiveSupport::KeyGenerator.new(user.email).generate_key("\xDB\x86\xE2$f\xBC\x8C\xF3\xC3\xAF\xEC\xB4u\x15\x92\xFD\x03\xE1\xA6J\x1Ed\xB9\xFB\x03\x97Mmj\xEB^`",32)
            crypt = ActiveSupport::MessageEncryptor.new(key)
            encrypted_name = crypt.encrypt_and_sign(user.name)   
            encrypted_screen_name = crypt.encrypt_and_sign(user.screen_name)   
            encrypted_last_name = crypt.encrypt_and_sign(user.last_name)
            user.encrypted_data = {'name' => encrypted_name, 'last_name' => encrypted_last_name, 'screen_name' => encrypted_screen_name}
            user.name = "Unknown"
            user.last_name = "user"
            user.screen_name = "Unknown"
            user.email = "unknown_user@scalable-learning.com"
            user.skip_confirmation!
            user.skip_reconfirmation!
            user.save
        end
    end

end
