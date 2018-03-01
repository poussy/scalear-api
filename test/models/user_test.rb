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

  test "finished lecture test" do
    user = users(:student_in_course3)
    lecture = lectures(:lecture3)
    assert_equal user.finished_lecture_test?(lecture), [-1, 0, 0, 2, 10]
  end
  
  test "anonymise and deanonymise user" do
    user = users(:user1)
    user.anonymise
    anonymised_user =  User.find(user.id)
    assert_equal anonymised_user.name, "Archived"
    assert_equal anonymised_user.email, "archived_user#{user.id}@scalable-learning.com"
    assert_equal anonymised_user.last_name, "user"
    assert_equal anonymised_user.screen_name, "Archived#{user.id}"
    assert_equal anonymised_user.university, "Archived"
    assert ['name','last_name','screen_name','university'].all? {|attr| anonymised_user.encrypted_data.key?(attr)}

    deanonymised_user = user.deanonymise("a.hossam.2010@gmail.com")
    
    assert_equal deanonymised_user.name, "ahmed"
    assert_equal deanonymised_user.email, "a.hossam.2010@gmail.com"
    assert_equal deanonymised_user.last_name, "hossam"
    assert_equal deanonymised_user.screen_name, "ahmed hossam"
    assert_equal deanonymised_user.university, "nile"
    assert_not deanonymised_user.encrypted_data
  end
  


end
