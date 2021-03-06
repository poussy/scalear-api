require 'simplecov'
SimpleCov.start 'rails'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def decode_json_response_body
    ActiveSupport::JSON.decode @response.body
  end

end

class ActiveRecord::Associations::CollectionProxy
    def last_created_record
      self.sort_by(&:created_at).last
    end
end

