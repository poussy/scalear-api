class AnnouncementsController < ApplicationController


private

  def announcement_params
    params.require(:announcement).permit(:announcement, :course_id, :date, :user_id)
  end
end
