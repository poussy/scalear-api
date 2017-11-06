class AnnouncementsController < ApplicationController

	load_and_authorize_resource  # @announcements is already loaded 

	before_action :set_zone
	# # before_filter :correct_user, :except => :index

	# # Removed to course model correct student && teacher
	# # def correct_user
	# # end

	def set_zone
		@course=Course.find(params[:course_id])
		Time.zone= @course.time_zone		
	end

	def index
		@announcements=@course.announcements.order(:created_at) #:updated_at #where(:user_id => current_user.id)
		render :json => @announcements
	end

	def show
		render json: @announcement
	end

	def create
		@announcementN = @course.announcements.build(announcement_params)
		@announcementN.user_id=current_user.id
		@announcementN.date=Time.zone.now
		@announcementN.announcement.gsub!(/\r\n/," ") if !@announcementN.announcement.blank?
		@users_emails= @course.users.pluck(:email) + @course.teachers.pluck(:email) + @course.guests.pluck(:email)
		if @announcementN.save
			@users_emails.each_slice(50).to_a.each do |m|
				UserMailer.delay.announcement_email(m,@announcementN,@course, I18n.locale) if !@users_emails.empty?
			end
			render json: { announcement:@announcementN, status: :created, :notice => I18n.t('controller_msg.announcement_successfully_created') }
		else
			render json: {errors:@announcementN.errors}, status: :unprocessable_entity 
		end
	end

	def update
		@users_emails= @course.users.pluck(:email) + @course.teachers.pluck(:email) + @course.guests.pluck(:email)
		if @announcement.update_attributes(announcement_params)
			@users_emails.each_slice(50).to_a.each do |m|
				UserMailer.delay.announcement_email(m,@announcement,@course, I18n.locale) if !@users_emails.empty?
			end
			render json: {announcement:@announcement, notice: I18n.t('controller_msg.announcement_successfully_updated')} 
		else
			render json: {errors:@announcement.errors}, status: :unprocessable_entity 
		end
	end

	def destroy
		@announcement.destroy
		render :json => {:notice => I18n.t('controller_msg.announcement_successfully_deleted')}
	end

	private
		def announcement_params
			params.require(:announcement).permit(:announcement, :course_id, :date, :user_id)
		end
end