
# encoding: utf-8
class SamlController < ApplicationController
#   skip_before_action :authenticate_user!
#   skip_authorize_resource
#   skip_before_action :check_user_signed_in?


  def saml_signin
    connect_to =params[:idp]
    session[:connect_to] = connect_to
    $connect_to= connect_to
    $settings = saml_settings
    request = Onelogin::Saml::Authrequest.new($settings)

    action, content = request.create({},connect_to)
    render json: {saml_url: content, action: action}
  end
  def clear_saml_domains
    SamlDomain.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!('saml_domains')
  end  
  def is_nordu_domains_valid(nordu_domains)
    if nordu_domains.instance_of?Array
       nordu_domains.each{|d| return false if !d.instance_of?Hash} 
       return true
    else 
       return false   
    end   
  end  
  def update_saml_domains(nordu_domains)
    clear_saml_domains
    nordu_domains.each do |d|
      new_domain = SamlDomain.create(:descr=>d["descr"],:title=>d["title"],:auth=>d["auth"],:keywords=>d["keywords"],:scope=>d["scope"],:entityID=>d["entityID"],:dataType=>d["type"],:hidden=>d["hidden"],:icon=>d["icon"])
      new_domain.save
    end  
  end 
  def get_domain
    begin 
      nordu_domains = JSON.load(open("https://md.nordu.net/swamid.json?role=idp"))
      update_saml_domains(nordu_domains) if is_nordu_domains_valid(nordu_domains)
    rescue StandardError, Rack::Timeout::RequestTimeoutException => e
      nordu_domains = SamlDomain.all
    end     
    render json: {domains:nordu_domains }
  end

  def consume
   
    @response = Onelogin::Saml::Response.new(params[:SAMLResponse])
    @response.settings = $settings

    connect_to = $connect_to.to_s
    begin
      @response.decrypt(Rails.application.config.saml[:keys][:private])
    rescue REXML::ParseException => ex
      puts “Failed: #{ex.message[/^.*$/]} (#{ex.message[/Line:\s\d+/]})”
      @response =  @response.force_encoding('UTF-8')
    end 
    redirect_url = validate_and_sign_in_user(@response.attributes)
    redirect_to redirect_url
   
  end

  def metadata
    $settings = saml_settings
    meta = Onelogin::Saml::Metadata.new($settings,nil)
    render :xml => meta.generate
  end

  private

    def validate_and_sign_in_user(response_attributes)
      attributes_names = {
        "urn:oid:1.3.6.1.4.1.5923.1.1.1.6"  => "eduPersonPrincipalName",
        "urn:oid:0.9.2342.19200300.100.1.3" => "mail",
        "urn:oid:2.5.4.42" => "givenName",
        "urn:oid:2.5.4.4"  => "sn",
        "urn:oid:2.5.4.10" => "o",
        "urn:oid:1.3.6.1.4.1.5923.1.1.1.9"  => "eduPersonScopedAffiliation",
        "urn:oid:1.3.6.1.4.1.5923.1.1.1.10" => "eduPersonTargetedID"
      }

      attributes = {}
      if(!response_attributes.nil?)
        response_attributes.each do |k,v|
          if !attributes_names[k].nil?
            attributes[attributes_names[k]]= v[1]
          elsif !v[0].nil?
            attributes[v[0]]= v[1]
          end
        end
      end

      if( (attributes["mail"].nil? || attributes["mail"].empty?))
        if(!attributes["email"].nil? && !attributes["email"].empty?)
          attributes["mail"] = attributes["email"]
        elsif(!attributes["eduPersonPrincipalName"].nil? && !attributes["eduPersonPrincipalName"].empty?)
          attributes["mail"] = attributes["eduPersonPrincipalName"]
        end
      end

      # add university from email domain if missings
      if attributes["o"].nil? || attributes["o"].empty?
        attributes["o"] = attributes["mail"].split('@')[1].match(/(\w+\.\w+$)/)[1] rescue ""
      end

      email = attributes["mail"].downcase rescue ""
      saml_user = User.find_by_email(email)
      if saml_user.nil?
        # search for anonymised users
        user = User.get_anonymised_user(email)
        if !user.nil? 
          user = user.deanonymise(email)
          user.last_sign_in_at = user.current_sign_in_at  
          user.current_sign_in_at = Time.now
          token = user.create_new_auth_token
          return "#/users/login?#{token.to_query}"
        end
       return "#/users/signup?#{attributes.to_query}&saml=true"
      else
        if !saml_user.saml
          saml_user.name        = attributes["givenName"] || saml_user.name
          saml_user.last_name   = attributes["sn"]        || saml_user.last_name
          saml_user.university  = attributes["o"]         || saml_user.university
          saml_user.saml = true
          saml_user.skip_confirmation!
          saml_user.save
        end
        saml_user.last_sign_in_at = saml_user.current_sign_in_at  
        saml_user.current_sign_in_at = Time.now
        token = saml_user.create_new_auth_token
        return "#/users/login?#{token.to_query}"
      end
    end

    def saml_settings
      settings = Onelogin::Saml::Settings.new

      settings.assertion_consumer_service_url = "https://#{request.host}/saml/consume"
      settings.issuer                         = "https://#{request.host}"
      settings.idp_cert_fingerprint           = "12:60:D7:09:6A:D9:C1:43:AD:31:88:14:3C:A8:C4:B7:33:8A:4F:CB"
      settings.idp_metadata = "https://md.nordu.net/entities/#{CGI.escape($connect_to ||'')}"
      settings.display_name="Scalable Learning"
      settings.description={}
      settings.description["en"]="Blended learning platform for interactive in-class and online education."
      settings.description["sv"]="Plattform för stöd av \"flipped classroom\" utbildning."
      settings.information_url="https://#{request.host}/home/about"
      settings.privacy_url="https://#{request.host}/home/privacy"
      settings.logo="https://#{request.host}/assets/logo-a66e557f3f93b4d5195033ba1a1527a3.png"
      settings.sp_cert = Rails.application.config.saml[:keys][:public]
      settings.org_name="Scalable Learning"
      settings.org_display_name="Scalable Learning"
      settings.org_url ="#{request.host}"

      settings.contact = []
      settings.contact << { :type =>  "technical", :company => "ScalableLearning", :email => "support@scalable-learning.com" }
      settings.contact << { :type =>  "administrative", :company => "ScalableLearning", :email => "support@scalable-learning.com" }

      settings.requested_attributes =[]
      settings.requested_attributes << {:name => "1.3.6.1.4.1.5923.1.1.1.6", :required => true} #eduPersonPrincipalName
      settings.requested_attributes << {:name => "0.9.2342.19200300.100.1.3", :required => true} #mail
      settings.requested_attributes << {:name => "2.5.4.42", :required => true} #givenName
      settings.requested_attributes << {:name => "2.5.4.4", :required => true} #sn
      settings.requested_attributes << {:name => "2.5.4.10", :required => true} #o
      settings.requested_attributes << {:name => "1.3.6.1.4.1.5923.1.1.1.9", :required => true} #eduPersonScopedAffiliation

      settings.edugain=true

      settings
    end
end