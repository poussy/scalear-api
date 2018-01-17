class ImpressionateController < ApplicationController

	def create
		course = Course.find(params[:course_id])
		if !course.nil?
			if current_user.roles.include?(Role.find(6))
				old = current_user
			else
				old = User.where(:email => current_user.email.split('@')[0]+'_preview@scalable-learning.com', :name => 'preview').first
			end
			if !old.nil?
				user = old
				preview_user_token = user.create_new_auth_token
				render json: {:user => user, :token => preview_user_token}
			else
				user =User.new(:email => current_user.email.split('@')[0]+'_preview@scalable-learning.com', :password => 'studentpreview1', :name => 'preview', :last_name => 'student', :screen_name =>'preview_student'+current_user.id.to_s, :university => 'preview univerisity', :completion_wizard =>{:intro_watched => true, :all => true}) #User.find(params[:user_id])
				user.skip_confirmation!
				user.roles << Role.find(2)
				user.roles << Role.find(6)
				if user.save
					course.users<<user
					preview_user_token = user.create_new_auth_token
					render json: {:user => user, :token=>preview_user_token}
				else
					render :json => {:errors => ["Failed to start previewing as student"]}, :status => :unprocessable_entity
				end
			end
		else
				render :json => {:errors => [I18n.t('controller_msg.course_does_not_exist')]}, :status => :unprocessable_entity
		end
	end

	# Revert the user impersonation
	def destroy
			old_user = User.find(params[:old_user_id])
			old_user_token = old_user.create_new_auth_token
			new_user = User.find(params[:new_user_id])
			new_user.async_destroy
			render json: {:msg => "No longer preview as student", :token=>old_user_token}
	end

	# def impressionate_as
	# end

end