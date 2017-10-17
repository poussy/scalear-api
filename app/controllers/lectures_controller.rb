class LecturesController < ApplicationController


private

  def lecture_params
    params.require(:lecture).permit(:course_id, :description, :name, :url, :group_id, :appearance_time, :due_date, :duration,:aspect_ratio, :slides, :appearance_time_module, :due_date_module,:required_module , :inordered_module, :position, :required, :inordered, :start_time, :end_time, :type )
  end
end
