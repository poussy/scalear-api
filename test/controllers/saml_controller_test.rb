require 'test_helper'

class SamlControllerTest < ActionDispatch::IntegrationTest
  test "validate_and_sign_in user doesn't exist" do
    saml_controller = SamlController.new
    response_attributes = {
        "urn:oid:0.9.2342.19200300.100.1.3"=>["mail","hany@gmail.com"],
        "urn:oid:2.5.4.10"=>["university","Cairo"]
      }

    assert_equal saml_controller.send(:validate_and_sign_in_user,response_attributes), {:redirect_to=>"#/users/signup?mail=hany%40gmail.com&o=Cairo&saml=true"}

  end

  test "validate_and_sign_in if user exists it should update user data and login" do
    saml_controller = SamlController.new
    response_attributes = {
        "urn:oid:0.9.2342.19200300.100.1.3"=>["mail","okasha@gmail.com"],
        "urn:oid:2.5.4.10"=>["university","Cairo"],
        "urn:oid:2.5.4.42"=>["givenName","saleh"],
        "uurn:oid:2.5.4.4"=>["sn","aly"],
      }

      # "urn:oid:1.3.6.1.4.1.5923.1.1.1.6"=>["eduPersonPrincipalName","Prinicipal_1"],
    assert_equal saml_controller.send(:validate_and_sign_in_user,response_attributes)[:sign_in]["id"],3
    assert_equal saml_controller.send(:validate_and_sign_in_user,response_attributes)[:sign_in]["name"],"saleh"
    assert_equal saml_controller.send(:validate_and_sign_in_user,response_attributes)[:sign_in]["last_name"],"aly"
    assert_equal saml_controller.send(:validate_and_sign_in_user,response_attributes)[:sign_in]["university"],"Cairo"
    assert_equal saml_controller.send(:validate_and_sign_in_user,response_attributes)[:sign_in]["saml"],true

    assert_not saml_controller.send(:validate_and_sign_in_user,response_attributes)[:token].nil?
   
  end
end
