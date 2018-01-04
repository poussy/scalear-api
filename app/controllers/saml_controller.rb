class SamlController < ApplicationController

	# skip_before_filter :authenticate_user!
	# skip_authorize_resource
	# skip_before_filter :check_user_signed_in?

	def saml_signin
		connect_to =params[:idp]
		session[:connect_to] = connect_to
		$connect_to= connect_to
		$settings = saml_settings
		request = Onelogin::Saml::Authrequest.new($settings)

		action, content = request.create({},connect_to)
		render json: {saml_url: content, action: action}
	end

	def get_domain
			render json: {domains: JSON.load(open("https://md.nordu.net/swamid.json?role=idp"))}
	end

	# def consume
	# end

	# def metadata
	# end
	
	private
		def saml_settings
				settings = Onelogin::Saml::Settings.new

				settings.assertion_consumer_service_url = "https://#{request.host}/saml/consume"
				settings.issuer                         = "https://#{request.host}"
				#settings.idp_sso_target_url             = "https://app.onelogin.com/saml/signon/" #{OneLoginAppId}
				settings.idp_cert_fingerprint           = "12:60:D7:09:6A:D9:C1:43:AD:31:88:14:3C:A8:C4:B7:33:8A:4F:CB"#OneLoginAppCertFingerPrint
				#settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
				# Optional for most SAML IdPs
				settings.idp_metadata = "http://md.nordu.net/entities/#{CGI.escape($connect_to ||'')}"#File.join(Rails.root, 'lib','assets', Rails.application.config.saml[:idp_metadata]) #"http://md.swamid.se/md/swamid-idp.xml" #has all!!
				#settings.idp_metadata="https://swamid.user.uu.se/idp/shibboleth"
				#settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
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