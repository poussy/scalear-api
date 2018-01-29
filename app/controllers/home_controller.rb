class HomeController < ApplicationController
	before_action :check_user_signed_in?, :only => [:notifications, :accept_course, :reject_course, :get_locale]

	# def get_locale
	# end

	def notifications
		@note={}
		final = {}
		@invitations = Invitation.where("lower(email) = ?", current_user.email.downcase)
		@invitations.each do |i|
			@note[i.id]={:course_id => i.course_id, :course_name => Course.select(:name).find(i.course_id).name, :user_name => User.select(:name).find(i.user_id).name, :role => Role.find(i.role_id).display_name}
		end
		shared_items=current_user.shared_withs.select([:id, :created_at, :updated_at, :data, :shared_with_id, :shared_by_id, :accept]).where(:accept => false)
		shared_items.each do |item|
			final[item.id] = {:id => item.id, :created_at => item.created_at, :updated_at => item.updated_at, :data => item.data, :shared_by_id => item.shared_by_id, :shared_with_id => item.shared_with_id, :sharer_email => item.sharer_email, :accept => item.accept}
		end
		render :json => {:invitations => @note, :shared_items => final}		
	end

	def accept_course
		inv= Invitation.find(params[:invitation])
		if inv.email.downcase==current_user.email.downcase
			@course= Course.find(inv.course_id)
			a= @course.teacher_enrollments.create(:user_id => current_user.id, :role_id => inv.role_id)
			if a.errors.empty?
				inv.destroy
				@invitations= Invitation.where("lower(email) = ?", current_user.email.downcase).size
				render :json => {:notice => I18n.t("notification.accept_invitation", course:@course.name), course_id: @course.id, :invitations => @invitations}
			else
				render :json => {:errors => [a.errors]}, :status => 400
			end
		else
			render :json => {:errors => I18n.t("controller_msg.wrong_credentials")}, :status => 404
		end		
	end

	def reject_course
		inv= Invitation.find(params[:invitation])
		if inv.email.downcase==current_user.email.downcase
			@course= Course.find(inv.course_id)
			inv.destroy
			@invitations= Invitation.where("lower(email) = ?", current_user.email.downcase).size
			render :json => {:notice => I18n.t("notification.reject_invitation", course:@course.name),:invitations => @invitations}
		else
			render :json => {:errors => I18n.t("controller_msg.wrong_credentials")}, :status => 404
		end		
	end

	def index 
			render json:{} 
	end

	def technical_problem
		if !user_signed_in?
			reporting_user = User.new()
			reporting_user.name = params[:name]
			reporting_user.email = params[:email]
		else
			reporting_user = current_user
		end
		if params[:issue_type]=='content'
			UserMailer.content_problem_email(  params[:url], reporting_user, params[:problem], params[:course].to_i,  params[:module].to_i, params[:lecture].to_i, params[:quiz].to_i, params[:agent] ,params[:version]).deliver
		else
			UserMailer.technical_problem_email(params[:url], reporting_user, params[:problem], params[:course].to_i,  params[:module].to_i, params[:lecture].to_i, params[:quiz].to_i, params[:agent] , params[:issue_website_type],params[:version]).deliver
		end
		render :json => {:done => true}
	end

	def contact_us
		reporting_user = User.new()
		reporting_user.name = params[:name]
		reporting_user.email = params[:email]
		UserMailer.contact_us_email(params[:url], reporting_user, params[:comment], params[:agent]).deliver
		render :json => {:done => true}  
	end

	def privacy
		redirect_to "#/privacy"
	end

	def about
		redirect_to "#/about"
	end

	# def test
	# end

end