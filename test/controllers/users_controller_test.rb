require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::ControllerHelpers
  test 'signing in' do
    # @request.env['devise.mapping'] = Devise.mappings[:user]
    user = users(:one)
    sign_in user
    p user
  end
end
