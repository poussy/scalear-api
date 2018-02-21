# encoding: utf-8
require "rexml/document"
require "rexml/xpath"

class LtiController < ApplicationController
	skip_before_action :authenticate_user!, raise: false
	# before_action :authenticate_user!
	
	skip_authorize_resource
	before_action :check_user_signed_in?, :only => [ :generate_new_lti_keys, :get_lti_custom_shared_key ]

	def embed_course_list
		courses = {}
		if params['consumer_key']
			lti_key_instance = LtiKey.find_by_consumer_key(params['consumer_key'])
			if lti_key_instance.user
				courses_common = lti_key_instance.user.teacher_enrollments.map(&:course_id) & current_user.teacher_enrollments.map(&:course_id)
			elsif lti_key_instance.organization && current_user.email.include?(lti_key_instance.organization.domain)
				courses_common = current_user.teacher_enrollments.map(&:course_id)
			end
			if courses_common.count == 0
				courses = nil
			end
		else
			courses_common = current_user.teacher_enrollments.map(&:course_id)
		end
		courses_common.each_with_index do |teacher_course_id , course_index|
			teacher_course = Course.find(teacher_course_id)
			courses[course_index] = {
			  "end_date"=>teacher_course.end_date ,"image_url"=>teacher_course.image_url ,"name"=>teacher_course.name ,"short_name"=>teacher_course.short_name ,
			  "start_date"=>teacher_course.start_date ,"ended"=>teacher_course.ended ,'enrollments'=>teacher_course.enrollments .size , "id" => teacher_course.id
			}
			courses[course_index]['groups'] = {}
			teacher_course.groups.all.each do |group |
				courses[course_index]['groups'][group.position] = {}
				courses[course_index]['groups'][group.position]['name'] = group.name
				courses[course_index]['groups'][group.position]['id'] = group.id
				courses[course_index]['groups'][group.position]['items_count'] = group.get_items.count
				courses[course_index]['groups'][group.position]['items'] ={}
				group.get_items.each do |item |
					courses[course_index]['groups'][group.position]['items'][item.position] = {}
					courses[course_index]['groups'][group.position]['items'][item.position]['name'] = item.name
					courses[course_index]['groups'][group.position]['items'][item.position]['id'] = item.id
					courses[course_index]['groups'][group.position]['items'][item.position]['type'] = item.class.name.downcase
				end
				if group.get_items.count == 0
					courses[course_index]['groups'][group.position]['items'] = nil
				end
			end
			if teacher_course.groups.count == 0
				courses[course_index]['groups'] = nil
			end
		end
		render json: {:courses => courses , :return_url => params['ext_content_return_url'] , courses_common: courses_common.count}		
	end

	def configuration
		meta_doc = REXML::Document.new
		root = meta_doc.add_element "cartridge_basiclti_link", {
			"xmlns" => "http://www.imsglobal.org/xsd/imslticc_v1p0",
			"xmlns:blti" => "http://www.imsglobal.org/xsd/imsbasiclti_v1p0",
			"xmlns:lticm" => "http://www.imsglobal.org/xsd/imslticm_v1p0",
			"xmlns:lticp" => "http://www.imsglobal.org/xsd/imslticp_v1p0",
			"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
			"xsi:schemaLocation" => "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
			http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
			http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
			http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd",
		}
		title = root.add_element "blti:title", {}
		title.text= "scalable-learning"
		description = root.add_element "blti:description", {}
		description.text= "Active Learning Online And In-class "
		icon = root.add_element "blti:icon", {}
		# <blti:icon>https://scalear-staging2.herokuapp.com/images/8bcb0e89.logo.png</blti:icon>
		# icon.text= root_url+"/images/8bcb0e89.logo.png"
		launch_url = root.add_element "blti:launch_url", {}
		launch_url.text= root_url+"/lti/lti_launch_use"
		extensions = root.add_element "blti:extensions", {"platform" => "canvas.instructure.com"}
		# <lticm:property name="tool_id">scalabing_learing</lticm:property>
		property_tool_id = extensions.add_element "lticm:property", {"name"=>"tool_id"}
		property_tool_id.text= "scalable-learning"
		# <lticm:property name="privacy_level">public</lticm:property>
		property_privacy_level = extensions.add_element "lticm:property", {"name"=>"privacy_level"}
		property_privacy_level.text= "public"
		# <lticm:property name="domain">scalable-learning</lticm:property>
		property_domain = extensions.add_element "lticm:property", {"name"=>"domain"}
		property_domain.text= "scalable-learning"
		# <lticm:options name="resource_selection">
		resource_selection_options = extensions.add_element "lticm:options", {"name"=>"resource_selection"}
		# <lticm:property name="url"root_url+>/lti/lti_launch</lticm:property>
		property_url = resource_selection_options.add_element "lticm:property", {"name"=>"url"}
		property_url.text= root_url+"/lti/lti_launch_embed"
		# <lticm:property name="text">scalable-learning</lticm:property>
		property_text = resource_selection_options.add_element "lticm:property", {"name"=>"text"}
		property_text.text= "scalable-learning"
		# <lticm:property name="selection_width">600</lticm:property>
		property_selection_width = resource_selection_options.add_element "lticm:property", {"name"=>"selection_width"}
		property_selection_width.text= "850"
		# <lticm:property name="selection_height">500</lticm:property>
		property_selection_height = resource_selection_options.add_element "lticm:property", {"name"=>"selection_height"}
		property_selection_height.text= "600"
		# <lticm:property name="enabled">true</lticm:property>
		property_enabled = resource_selection_options.add_element "lticm:property", {"name"=>"enabled"}
		property_enabled.text= "true"
		meta_doc << REXML::XMLDecl.new(1.0,"utf-8")
		ret = ""
		meta_doc.write(ret, 1)
		render xml: ret
	end

	def generate_new_lti_keys
		if params['type'] == "user"
			lti_key_user = LtiKey.find_by_user_id(current_user.id)
			if lti_key_user
				consumer_key = LtiKey.last.generate_random_consumer_key
				shared_sceret = LtiKey.last.generate_random_shared_sceret
				lti_key_user.update_attributes(:consumer_key => consumer_key , :shared_sceret => shared_sceret)
			else
				begin
					LtiKey.create( :user_id =>  current_user.id)
				rescue Exception => e
					p e
				end
				lti_key = current_user.lti_key
				consumer_key = lti_key.consumer_key
				shared_sceret = lti_key.shared_sceret
			end
		else
			consumer_key = nil
		end
		# redirect_to "#/"
		render json: {updated: true, consumer_key:consumer_key , shared_sceret:shared_sceret}		
	end

	def get_lti_custom_shared_key
		## Get all domains that organization hava a lti_Key
		consumer_key = nil
		shared_sceret = nil
		lti_key_domains = Organization.find(LtiKey.pluck(:organization_id).compact.uniq).map(&:domain)
		if params['type'] == "user"
			if lti_key_domains.select{|domain| current_user.email.include?(domain) }.size>0 # email domain have an lti key organization
				consumer_key = 'organization'
				shared_sceret = 'organization'
			else
				lti_key_user = LtiKey.find_by_user_id(current_user.id)
				if !lti_key_user.nil?
					consumer_key = lti_key_user.consumer_key
					shared_sceret = lti_key_user.shared_sceret
				end
			end
		end
		render json: {shared_sceret: shared_sceret, consumer_key:consumer_key, lti_url_xml: root_url[0...-2]+"lti/configuration", lti_url_embed:root_url[0...-2]+"lti/lti_launch_embed"}
	end

	def lti_launch_embed
		consumer_key = params['oauth_consumer_key']
		lti_key_instance = LtiKey.find_by_consumer_key(consumer_key)

		if lti_key_instance
			if lti_key_instance.organization && !(params['lis_person_contact_email_primary'].include?(lti_key_instance.organization.domain))
				redirect_to "#/"
			else
				authenticator = IMS::LTI::Services::MessageAuthenticator.new(request.url, request.request_parameters , lti_key_instance.shared_sceret)
				if authenticator.valid_signature?
					user_sign_in_token , user = user_sign_in
					if user_sign_in_token
						if params['tool_consumer_info_product_family_code'] == 'canvas' 
							redirect_to("#/lti_course_list?return_url="+params['ext_content_return_url']+"&consumer_key="+consumer_key+'&'+user_sign_in_token.to_query)
						else
							resource_context_id = params['resource_link_id']+'scalable_learning'+params['context_id']
							resource_context = LtiResource.find_by_resource_context_id(resource_context_id)
							#check resoures_link_id&context_id is in the table or not 
							if resource_context
								# if yes call redirect_url_student_teacher function and redirected to the return url 
								sl_type_name_type_id = resource_context.sl_type_name_type_id.split('__')
								url , course  = redirect_url_student_teacher( sl_type_name_type_id[0] , params['roles'], sl_type_name_type_id[1])
								if params['roles'] != "Instructor"
									if !(course.users.map(&:id).include?(current_user.id)) && !(course.teachers.map(&:id).include?(current_user.id))
										course.users<<current_user
										course.save
									end
								end
								redirect_to url+"?"+user_sign_in_token.to_query
							else
								#if not redirect to lti_course_list
								#used #sl# to make sure that it will not repeat in any place
								resource_context_id = params['resource_link_id']+'scalable_learning'+params['context_id']
								redirect_to "#/lti_course_list?return_url=lti_tool_redirect&consumer_key="+consumer_key+"&resource_context_id="+resource_context_id+'&'+user_sign_in_token.to_query
							end
						end
					else ### create new account and user is Instructor
						redirect_to "#/lti_course_list?full_name="+params['lis_person_name_full']+"&email="+params['lis_person_contact_email_primary']+
						"&first_name="+params['lis_person_name_given']+"&last_name="+params['lis_person_name_family']
					end
				else
					# handle invalid OAuth
					redirect_to "#/"
				end
			end
		else
			# "invalid consumer_key"
			redirect_to "#/"
		end	
	end

	def lti_launch_use
		consumer_key = params['oauth_consumer_key']
		lti_key_instance = LtiKey.find_by_consumer_key(consumer_key)
		if lti_key_instance
			authenticator = IMS::LTI::Services::MessageAuthenticator.new(request.url.partition('?').first, request.request_parameters , lti_key_instance.shared_sceret)
			if authenticator.valid_signature?
				## TO use scalaleLearning
				## check the student can sig in AND ENROLL STUDENT
				url , course = redirect_url_student_teacher(params['sl_type'],params['roles'],params['sl_type_id'])
				redirect_boolean = 'true'
				status = 'nil'
				user_sign_in_token , user = user_sign_in
				if user_sign_in_token
					if params['roles'] != "Instructor"
						if !(course.users.map(&:id).include?(user.id)) && !(course.teachers.map(&:id).include?(user.id))
							course.users<<user
							course.save
						end
					elsif !(course.teachers.map(&:id).include?(user.id))
						redirect_boolean = 'false'
						status = 'no_teacher_enrollment'
					end
					redirect_to "#/lti_sign_in_token?redirect_boolean="+redirect_boolean+"&status="+status+"&"+user_sign_in_token.to_query+"&redirect_local_url="+url[1..-1]
				else ### create new account for teacher
					redirect_to "#/lti_course_list?full_name="+params['lis_person_name_full']+"&email="+params['lis_person_contact_email_primary']+
					"&first_name="+params['lis_person_name_given']+"&last_name="+params['lis_person_name_family']
				end
			else
				# handle invalid OAuth
				redirect_to "#/users/edit"+'?'+user_sign_in_token.to_query
			end
		else
			redirect_to "#/"
		end
	end

	def lti_tool_redirect_save_data
		# {""=>"", "resource_context_id"=>"51scalable_learning11242", "type"=>"course", "type_id"=>"503", "controller"=>"lti", "action"=>"lti_tool_redirect_save_data", "locale"=>"en"}
		resource_context = LtiResource.find_by_resource_context_id(params['resource_context_id'])
		sl_type_name_type_id = params['type']+"__"+ params['type_id']
		if resource_context
			resource_context.update_attributes(sl_type_name_type_id:sl_type_name_type_id)
		else
			LtiResource.create(sl_type_name_type_id:sl_type_name_type_id , resource_context_id:params['resource_context_id'])
		end
		render json: {saved: true}    		
	end

	private
		def redirect_url_student_teacher(sl_type,roles,sl_type_id)
			if sl_type == 'course'
				course = Course.find(sl_type_id)
				roles == "Instructor" ? url = "#/courses/#{course.id}/information" : url = "#/courses/#{course.id}/course_information"
			elsif sl_type == 'group'
				group  = Group.find(sl_type_id)
				course = group.course
				url = "#/courses/#{course.id}/modules/#{group.id}"
				roles == "Instructor" ? url += "/course_editor" : url += "/courseware/overview"
			elsif sl_type == 'lecture'
				lecture  = Lecture.find(sl_type_id)
				course = lecture.course
				group = lecture.group
				url = "#/courses/#{course.id}/modules/#{group.id}"
				roles == "Instructor" ? url += "/course_editor/lectures/#{lecture.id}" : url += "/courseware/lectures/#{lecture.id}"
			elsif sl_type == 'quiz'
				quiz  = Quiz.find(sl_type_id)
				course = quiz.course
				group = quiz.group
				url = "#/courses/#{course.id}/modules/#{group.id}"
				roles == "Instructor" ? url += "/course_editor/quizzes/#{quiz.id}" : url += "/courseware/quizzes/#{quiz.id}"
			elsif sl_type == 'customlink'
				custom_link = CustomLink.find(sl_type_id)
				course = custom_link.course
				group = custom_link.group
				url = "#/courses/#{course.id}/modules/#{group.id}"
				roles == "Instructor" ? url += "/course_editor/link/#{custom_link.id}" : url = custom_link.url
			else
				url = "#/courses"
			end
			return url , course
		end

		def user_sign_in
			if params['custom_canvas_user_id']
				canvas_id_user = User.find_by_canvas_id(params['custom_canvas_user_id'])
			end
			canvas_login_user = User.find_by_email(params['lis_person_contact_email_primary'].downcase)
			if !canvas_id_user.nil?
				canvas_id_user.canvas_last_signin = DateTime.now
				canvas_id_user.save
				token = canvas_id_user.create_new_auth_token
				return token , canvas_id_user
			elsif !canvas_login_user.nil? # notFounded Check Email        
				if params['custom_canvas_user_id']
					canvas_login_user.canvas_id = params['custom_canvas_user_id']
				end
				canvas_login_user.canvas_last_signin = DateTime.now
				canvas_login_user.save
				token =  canvas_login_user.create_new_auth_token
				return token , canvas_login_user
			else # If teacher create new course
				# check if student or teacher  // Learner  OR
				if params['roles'] == "Instructor"
					return false , false
				else
					user =User.new(params[:user])
					user.password = Devise.friendly_token[0,20]
					user.completion_wizard = {:intro_watched => true}
					user.skip_confirmation!
					user.roles << Role.find(1)
					user.roles << Role.find(2)
					# user.email = params['custom_canvas_user_login_id']
					user.email = params['lis_person_contact_email_primary']
					user.name = params['lis_person_name_given']
					if params['lis_person_name_family'] == ''
						user.last_name = '__'
					else
						user.last_name = params['lis_person_name_family']
					end
					user.screen_name = params['lis_person_name_full']
					user.university = '-'
					if params['custom_canvas_user_id']
						user.canvas_id = params['custom_canvas_user_id']
					end
					user.canvas_last_signin = DateTime.now
					if user.save
						token = user.create_new_auth_token
						return token , user
					else
						return false, false
					end
				end
			end
		end
end