require 'test_helper'

class ArchiveUsersTaskTest < ActiveSupport::TestCase
    def setup
        ENV['hash_salt']="test_salt"
        ENV['anonymisation_report_mail']="test@mail.com"

        User.find(6).update_attribute('current_sign_in_at',1.year.ago-8.days)
        User.find(7).update_attribute('current_sign_in_at',1.year.ago-10.days)

        #test case1: the user's domain doesnt exist
        poussy=User.create(:id=>20,:email=>'poussy@novelari.com')
        poussy.save
        poussy.update_attribute('current_sign_in_at',1.year.ago-8.days)

        #test case2: the user's domain exit
        david=User.create(:id=>21,:email=>'david@novelari.com')
        david.save
        david.update_attribute('current_sign_in_at',1.year.ago-20.days)
        ScalearApi::Application.load_tasks
    end
    
    test "inactive users should be anonymized" do
        Delayed::Worker.delay_jobs = false
        # task only runs on sunday
        while Date.today.wday!=0
            travel 1.day
        end

        assert_difference "User.where('encrypted_data IS NOT null').count",4 do
            Rake::Task['gdpr:archive_users'].invoke
        end

        assert_equal User.where('encrypted_data IS NOT null').pluck(:id).sort, [6,7,20,21].sort
        assert_equal ActionMailer::Base.deliveries.size,4
        assert_equal "{\"to\":[\"saleh@gmail.com\",\"ahmed@gmail.com\",\"poussy@novelari.com\",\"david@novelari.com\"]}" , ActionMailer::Base.deliveries[2].header['X-SMTPAPI'].value
        assert_includes ["test@mail.com",'david@novelari.com'], ActionMailer::Base.deliveries[1]['to'].value
        
        assert_equal UsersRole.where(:user_id=>20).first.organization.domain,"novelari.com"
        assert_equal UsersRole.where(:user_id=>21).first.organization.domain,"novelari.com"
        assert_equal UsersRole.where(:user_id=>6).first.organization.domain,"gmail.com"
        assert_equal UsersRole.where(:user_id=>7).first.organization.domain,"gmail.com"
    end

end