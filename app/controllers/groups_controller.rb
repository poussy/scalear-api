class GroupsController < ApplicationController


private

  def group_params
    params.require(:group).permit(:course_id, :description, :name, :appearance_time, :position, :due_date, :inorder ,:required)
  end
end
