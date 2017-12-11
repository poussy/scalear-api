class OnlineMarkersController < ApplicationController
	load_and_authorize_resource
	
	def update
		if @online_marker.update_attributes(online_marker_params)
			render json: {}
		else
			render json: {errors: @online_marker.errors}, status: :unprocessable_entity
		end
	end

	def validate_name
		params[:online_marker].each do |key, value|
			@online_marker[key]=value
		end
		if @online_marker.valid?
			render json: {}, status: :ok				
		else
			render json: {errors: @online_marker.errors.full_messages}, status: :unprocessable_entity
		end
	end

	def destroy
		# online_marker = OnlineMarker.find(params[:id])
		@online_marker.destroy
		render json: {:notice => [ I18n.t("controller_msg.marker_successfully_deleted")]}		
	end

	def get_marker_list
		lecture = Lecture.find(params[:lecture_id])
		render json: {:markerList => lecture.online_markers, :status=>"success"}		
	end

	# def update_hide
	# end

	def online_marker_params
		params.require(:online_marker).permit(:lecture_id,:group_id,:course_id,:time,:annotation,:title,:hide)
	end

end