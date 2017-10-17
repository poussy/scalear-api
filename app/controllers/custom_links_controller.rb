class CustomLinksController < ApplicationController


private

  def custom_link_params
    params.require(:custom_link).permit(:course_id, :group_id, :name, :url, :position, :course_position)
  end
end
