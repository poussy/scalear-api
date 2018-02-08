require 'test_helper'

class SamlControllerTest < ActionDispatch::IntegrationTest
  test "validate_and_sign_in user doesn't exist" do
    saml_controller = SamlController.new
    response_attributes = {
        "urn:oid:0.9.2342.19200300.100.1.3"=>["mail","hany@gmail.com"],
        "urn:oid:2.5.4.10"=>["university","Cairo"]
      }

    assert_equal saml_controller.send(:validate_and_sign_in_user,response_attributes), "#/users/signup?mail=hany%40gmail.com&o=Cairo&saml=true"

  end

  test "validate_and_sign_in if user exists it should update user data and login" do
    saml_controller = SamlController.new
    response_attributes = {
        "urn:oid:0.9.2342.19200300.100.1.3"=>["mail","okasha@gmail.com"],
        "urn:oid:2.5.4.10"=>["university","Cairo"],
        "urn:oid:2.5.4.42"=>["givenName","saleh"],
        "uurn:oid:2.5.4.4"=>["sn","aly"],
      }
    
    assert_match /\#\/users\/login\?access-token.*uid\=okasha%40gmail\.com/, saml_controller.send(:validate_and_sign_in_user,response_attributes)
    
    #updated user name and last name
    assert_equal User.find(3).name, "saleh"
    assert_equal User.find(3).last_name, "aly"
    assert_equal User.find(3).saml, true
    
  end
end

