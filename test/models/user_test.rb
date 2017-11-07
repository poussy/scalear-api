require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "user should not be valid if missing name, last_name, screen_name or university" do
    u = users(:user1)
    assert u.valid?

    u.last_name = nil

    assert u.invalid?

  end

  test "screen name should be unique" do
    #same last_name exists in fixture user1
    u2 = User.create(name:"ahmed", screen_name:"ahmed hossam", last_name:"hossam", university:"cairo")

    assert u2.invalid?
  end

  test "'User' role should be added to user when created" do
    u = users(:user1)
    user_role = Role.find_by_name("User")

    assert_equal u.roles[0], user_role
  end


end
