require 'test_helper'

class ArchiveUsersTaskTest < ActiveSupport::TestCase
    def setup
        ENV['hash_salt']="test_salt"
        ENV['anonymisation_report_mail']="test@mail.com"

        User.find(6).update_attribute('updated_at',1.year.ago-8.days)
        User.find(7).update_attribute('updated_at',1.year.ago-10.days)
        ScalearApi::Application.load_tasks
    end
    
    test "inactive users should be anonymized" do
        Delayed::Worker.delay_jobs = false
        assert_difference "User.where('encrypted_data IS NOT null').count",2 do
            Rake::Task['gdpr:archive_users'].invoke
        end

        assert_equal User.where('encrypted_data IS NOT null').pluck(:id).sort, [6,7].sort
        assert_equal ActionMailer::Base.deliveries.size,3
        assert_includes ["saleh@gmail.com","ahmed@gmail.com","test@mail.com"], ActionMailer::Base.deliveries[0]['to'].value
        assert_includes ["saleh@gmail.com","ahmed@gmail.com","test@mail.com"], ActionMailer::Base.deliveries[1]['to'].value
        assert_includes ["saleh@gmail.com","ahmed@gmail.com","test@mail.com"], ActionMailer::Base.deliveries[2]['to'].value
    end
end