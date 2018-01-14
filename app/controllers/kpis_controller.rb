class KpisController < ApplicationController
	# include KpisHelper 	def secondToHoursString(t)

	# before_filter :init_tempodb ,:authorize

	# def authorize
	# end

	# def init_tempodb
	# end

	# def init_series
	# end

	# def destroy_series
	# end

	# def kpi_job
	# end

	# def init_data
	# end

	# def read_data
	# end

	# def read_totals
	# end

	def read_totals_for_duration
		render json: Course.school_admin_statistics_course_ids(params[:start_date],params[:end_date], params[:domain], current_user)
	end

	# def get_report_data_course_duration
	# end

	# def read_series
	# end

	# def export_school_statistics
	# end

	# private
	# 	def get_statistics(retrive_date)
	# 	end

	# 	def get_totals(school)
	# 	end

	# 	def get_totals_per_day(retrive_date)
	# 	end
end