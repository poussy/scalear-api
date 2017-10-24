class CoursesController < ApplicationController


private

  def course_params
    params.require(:course).permit(:description, :end_date, :name, :prerequisites, :short_name, :start_date, :user_ids, :user_id, :time_zone, :discussion_link, :importing, :image_url ,:disable_registration	)
  end
end
